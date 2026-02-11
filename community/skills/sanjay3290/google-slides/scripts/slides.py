#!/usr/bin/env python3
"""
Google Slides API operations.
Lightweight alternative to the full Google Workspace MCP server.
"""

import argparse
import json
import re
import sys
import urllib.request
import urllib.error
import urllib.parse
from typing import Optional

from auth import get_valid_access_token

SLIDES_API_BASE = "https://slides.googleapis.com/v1"
DRIVE_API_BASE = "https://www.googleapis.com/drive/v3"


def extract_presentation_id(presentation_id_or_url: str) -> str:
    """Extract presentation ID from URL or return as-is if already an ID."""
    # Match Google Slides URL patterns
    patterns = [
        r'docs\.google\.com/presentation/d/([a-zA-Z0-9_-]+)',
        r'drive\.google\.com/.*?/d/([a-zA-Z0-9_-]+)',
    ]
    for pattern in patterns:
        match = re.search(pattern, presentation_id_or_url)
        if match:
            return match.group(1)
    return presentation_id_or_url


def api_request(method: str, url: str, data: Optional[dict] = None, params: Optional[dict] = None) -> dict:
    """Make an authenticated request to a Google API."""
    token = get_valid_access_token()
    if not token:
        return {"error": "Failed to get access token"}

    if params:
        url += "?" + urllib.parse.urlencode(params)

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    body = json.dumps(data).encode('utf-8') if data else None

    try:
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8') if e.fp else str(e)
        return {"error": f"HTTP {e.code}: {error_body}"}
    except urllib.error.URLError as e:
        return {"error": f"Request failed: {e.reason}"}
    except json.JSONDecodeError:
        return {"error": "Invalid JSON response"}


def extract_text_from_text_content(text_content: dict) -> str:
    """Extract plain text from a Slides text content object."""
    text = ''
    text_elements = text_content.get('textElements', [])
    for element in text_elements:
        if 'textRun' in element and element['textRun'].get('content'):
            text += element['textRun']['content']
        elif 'paragraphMarker' in element:
            text += '\n'
    return text


def get_text(presentation_id: str) -> dict:
    """Get all text content from a presentation."""
    pid = extract_presentation_id(presentation_id)

    params = {
        "fields": "title,slides(pageElements(shape(text,shapeProperties),table(tableRows(tableCells(text)))))"
    }

    result = api_request("GET", f"{SLIDES_API_BASE}/presentations/{pid}", params=params)

    if "error" in result:
        return result

    content = ''

    # Add presentation title
    if result.get('title'):
        content += f"Presentation Title: {result['title']}\n\n"

    # Process each slide
    slides = result.get('slides', [])
    for slide_index, slide in enumerate(slides):
        content += f"\n--- Slide {slide_index + 1} ---\n"

        page_elements = slide.get('pageElements', [])
        for element in page_elements:
            # Extract text from shapes
            if 'shape' in element and 'text' in element['shape']:
                shape_text = extract_text_from_text_content(element['shape']['text'])
                if shape_text.strip():
                    content += shape_text + '\n'

            # Extract text from tables
            if 'table' in element and 'tableRows' in element['table']:
                content += '\n--- Table Data ---\n'
                for row in element['table']['tableRows']:
                    row_text = []
                    for cell in row.get('tableCells', []):
                        if 'text' in cell:
                            cell_text = extract_text_from_text_content(cell['text'])
                            row_text.append(cell_text.strip())
                        else:
                            row_text.append('')
                    content += ' | '.join(row_text) + '\n'
                content += '--- End Table Data ---\n'

        content += '\n'

    return {"text": content.strip()}


def find_presentations(query: str, page_size: int = 10, page_token: Optional[str] = None) -> dict:
    """Find presentations by search query using Drive API."""
    # Build Drive search query for presentations
    mime_type = "application/vnd.google-apps.presentation"
    drive_query = f"mimeType='{mime_type}' and trashed=false"

    if query:
        # Escape single quotes in query
        escaped_query = query.replace("'", "\\'")
        drive_query += f" and (name contains '{escaped_query}' or fullText contains '{escaped_query}')"

    params = {
        "pageSize": page_size,
        "fields": "nextPageToken,files(id,name,modifiedTime,owners)",
        "q": drive_query
    }

    if page_token:
        params["pageToken"] = page_token

    result = api_request("GET", f"{DRIVE_API_BASE}/files", params=params)

    if "error" in result:
        return result

    return {
        "presentations": result.get("files", []),
        "nextPageToken": result.get("nextPageToken")
    }


def get_metadata(presentation_id: str) -> dict:
    """Get presentation metadata."""
    pid = extract_presentation_id(presentation_id)

    params = {
        "fields": "presentationId,title,slides(objectId),pageSize,notesMaster,masters,layouts"
    }

    result = api_request("GET", f"{SLIDES_API_BASE}/presentations/{pid}", params=params)

    if "error" in result:
        return result

    metadata = {
        "presentationId": result.get("presentationId"),
        "title": result.get("title"),
        "slideCount": len(result.get("slides", [])),
        "pageSize": result.get("pageSize"),
        "hasMasters": bool(result.get("masters")),
        "hasLayouts": bool(result.get("layouts")),
        "hasNotesMaster": bool(result.get("notesMaster"))
    }

    return metadata


def main():
    parser = argparse.ArgumentParser(description="Google Slides API operations")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # get-text
    get_text_parser = subparsers.add_parser("get-text", help="Get text content from a presentation")
    get_text_parser.add_argument("presentation", help="Presentation ID or URL")

    # find
    find_parser = subparsers.add_parser("find", help="Find presentations by search query")
    find_parser.add_argument("query", help="Search query")
    find_parser.add_argument("--limit", type=int, default=10, help="Max results to return")
    find_parser.add_argument("--page-token", help="Pagination token")

    # get-metadata
    get_metadata_parser = subparsers.add_parser("get-metadata", help="Get presentation metadata")
    get_metadata_parser.add_argument("presentation", help="Presentation ID or URL")

    args = parser.parse_args()

    if args.command == "get-text":
        result = get_text(args.presentation)
    elif args.command == "find":
        result = find_presentations(args.query, args.limit, args.page_token)
    elif args.command == "get-metadata":
        result = get_metadata(args.presentation)
    else:
        result = {"error": f"Unknown command: {args.command}"}

    print(json.dumps(result, indent=2))

    if isinstance(result, dict) and "error" in result:
        sys.exit(1)


if __name__ == "__main__":
    main()
