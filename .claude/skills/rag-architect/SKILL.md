---
name: rag-architect
cluster: ai-applications
description: "Retrieval-Augmented Generation system design. Vector databases, embedding models, chunking strategies, hybrid search, reranking, RAG evaluation. Use when building RAG pipelines, selecting vector stores, designing document ingestion, or optimizing retrieval quality."
---

# RAG Architect

> **Version**: 1.3.0 | **Last updated**: 2026-02-14

## Purpose

RAG grounds LLM outputs in factual knowledge — without it, models hallucinate. A well-designed RAG system balances retrieval precision, latency, and cost while maintaining freshness of the knowledge base. Poor RAG design leads to irrelevant context, hallucinated citations, and user distrust.

---

## Vector Database Selection

| Database | Best For | Hosting | Scale | Cost Model |
|----------|----------|---------|-------|------------|
| pgvector | Existing PostgreSQL, < 10M vectors | Self-managed | Moderate | Included with PG |
| Pinecone | Managed, low-ops teams | SaaS | High | Per-vector/query |
| Qdrant | Self-hosted, filtering-heavy | Self/Cloud | High | Open source |
| Weaviate | Multi-modal, GraphQL API | Self/Cloud | High | Open source |
| Chroma | Prototyping, small datasets | Embedded | Low | Free |

**Rule**: start with pgvector if already using PostgreSQL. Move to a dedicated vector DB only when pgvector performance degrades (>100ms p95 at scale). Record the decision in an ADR.

---

## Chunking Strategies

Chunking determines retrieval quality more than embedding model choice. Get this wrong and no amount of reranking fixes it.

```typescript
interface ChunkConfig {
  maxTokens: number;      // 256-512 for precise retrieval, 512-1024 for context-rich
  overlapTokens: number;  // 10-20% of maxTokens
  strategy: 'fixed' | 'sentence' | 'semantic' | 'recursive';
}

interface Chunk {
  content: string;
  metadata: {
    source: string;
    chunkIndex: number;
    tokenCount: number;
    tenantId: string;
    documentType: string;
    createdAt: string;
  };
}

// Recursive character splitter with overlap
function chunkDocument(text: string, config: ChunkConfig): Chunk[] {
  const separators = ['\n\n', '\n', '. ', ' '];
  return recursiveSplit(text, separators, config.maxTokens, config.overlapTokens);
}
```

**Decision guide**: fixed-size for uniform documents (code, logs), sentence-boundary for prose, semantic for mixed-format documents, recursive for general-purpose. Always include metadata enrichment (source, timestamp, section, tenant_id) in every chunk.

---

## Retrieval Pipeline

Hybrid search (vector + BM25 keyword) is the default — pure semantic search misses exact matches (product IDs, error codes, acronyms).

```
Query → Query Expansion → Embedding
  ├─→ Vector Search (semantic similarity)
  └─→ BM25 Search (keyword matching)
       ↓
  Reciprocal Rank Fusion → Reranker (cross-encoder) → Top-K → LLM Context
```

```typescript
interface RetrievalOptions {
  query: string;
  tenantId: string;
  topK: number;
  filters?: {
    documentType?: string;
    dateRange?: { from: Date; to: Date };
    tags?: string[];
  };
  hybridAlpha?: number; // 0 = pure keyword, 1 = pure vector, 0.7 default
}

async function retrieve(options: RetrievalOptions): Promise<ScoredChunk[]> {
  const embedding = await embedQuery(options.query);

  const [vectorResults, keywordResults] = await Promise.all([
    vectorSearch(embedding, {
      tenantId: options.tenantId,
      topK: options.topK * 3, // over-fetch for reranking
      filters: options.filters,
    }),
    bm25Search(options.query, {
      tenantId: options.tenantId,
      topK: options.topK * 3,
      filters: options.filters,
    }),
  ]);

  const fused = reciprocalRankFusion(vectorResults, keywordResults, options.hybridAlpha ?? 0.7);
  return rerank(options.query, fused, options.topK);
}
```

---

## Embedding Model Selection

| Model | Dimensions | Cost | MTEB Score | Notes |
|-------|-----------|------|------------|-------|
| text-embedding-3-small | 1536 | $0.02/1M tokens | ~62 | Good cost/quality ratio |
| text-embedding-3-large | 3072 | $0.13/1M tokens | ~64 | Best OpenAI option |
| Cohere embed-v3 | 1024 | $0.10/1M tokens | ~65 | Strong multilingual |
| BGE-large-en-v1.5 | 1024 | Self-hosted | ~64 | Open source, no API cost |
| E5-mistral-7b-instruct | 4096 | Self-hosted | ~66 | Best open source, high compute |

**Rule**: always evaluate on your domain data, not just MTEB benchmarks. A smaller model fine-tuned on domain data often beats a larger general model. Never hardcode the embedding model — use an abstraction layer for model swapping.

---

## RAG Evaluation

| Metric | Measures | Target | Tool |
|--------|----------|--------|------|
| Precision@K | % of retrieved docs that are relevant | > 80% | Custom / RAGAS |
| Recall@K | % of relevant docs that are retrieved | > 70% | Custom / RAGAS |
| MRR | How high the first relevant doc ranks | > 0.7 | Custom |
| Faithfulness | LLM answer grounded in retrieved context | > 90% | RAGAS / TruLens |
| Answer relevancy | LLM answer addresses the query | > 85% | RAGAS / TruLens |

Evaluate on a **golden dataset** of query-document-answer triples. Minimum 100 examples for meaningful signal. Re-evaluate after every change to chunking, embeddings, or retrieval logic. Track metrics in CI — retrieval quality is a regression target.

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Default chunk size without evaluation | 512 tokens is arbitrary; optimal size varies by document type and retrieval use case | Benchmark 256, 512, 1024 on your golden dataset |
| Vector search only | Pure semantic search misses exact matches (product IDs, error codes, acronyms) | Hybrid search: vector + BM25 with reciprocal rank fusion |
| Ignoring retrieval metrics | Optimizing only the LLM prompt while retrieval returns irrelevant context | Measure Precision@K, Recall@K, MRR before tuning prompts |
| Monolithic embeddings | One embedding model for all content types (code, prose, tables) underperforms | Evaluate embedding models per content type; consider separate indexes |
| No metadata filtering | Searching across all documents for every query wastes compute and hurts precision | Filter by tenant_id, document_type, date_range before search |
| Stale knowledge base | Ingestion pipeline runs once; knowledge drifts from source of truth | Continuous sync with source documents; track staleness metrics |

---

## For Claude Code

When building RAG systems: use hybrid search (vector + BM25) as default retrieval strategy, never vector-only. Generate chunking pipelines with configurable chunk size and overlap — default 512 tokens with 50 token overlap for prose, 256 tokens for code. Include metadata enrichment (source, timestamp, section, tenant_id) in every chunk. Use pgvector for prototypes and <10M vectors, recommend dedicated vector DB for larger scale. Generate retrieval functions with metadata filtering and reranking step. Include evaluation scripts measuring Precision@K, Recall@K, MRR, and faithfulness. Never hardcode embedding model — use an abstraction layer for model swapping. Always generate a `ChunkConfig` interface and make chunking strategy configurable. Generate idempotent ingestion pipelines with deduplication (content hash). Include structured logging with correlation IDs for retrieval latency monitoring. When generating vector search schemas, include HNSW index configuration with tunable `ef_construction` and `m` parameters.

*Internal references*: `data-modeling/SKILL.md`, `observability/SKILL.md`, `api-design/SKILL.md`, `caching-search/SKILL.md`
