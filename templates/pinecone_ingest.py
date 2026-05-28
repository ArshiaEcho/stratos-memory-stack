#!/usr/bin/env python3
"""
Pinecone ingest. Stratos Memory Stack, layer 4.

Usage:
    python3 pinecone_ingest.py path/to/document.md
    python3 pinecone_ingest.py path/to/folder/  (ingests all .md files)

Requires:
    pip install pinecone-client openai python-dotenv
    .env file with PINECONE_API_KEY and OPENAI_API_KEY

Configure:
    INDEX_NAME below. Create the index in the Pinecone console first
    with dimension=1536 (matches text-embedding-3-small) and metric=cosine.
"""

import os
import sys
import hashlib
from pathlib import Path
from dotenv import load_dotenv
from pinecone import Pinecone
from openai import OpenAI

load_dotenv()

INDEX_NAME = "your-vault"
EMBEDDING_MODEL = "text-embedding-3-small"
CHUNK_SIZE = 1200
CHUNK_OVERLAP = 200

pc = Pinecone(api_key=os.environ["PINECONE_API_KEY"])
openai_client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
index = pc.Index(INDEX_NAME)


def chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP):
    chunks = []
    start = 0
    while start < len(text):
        end = start + size
        chunks.append(text[start:end])
        start = end - overlap
    return chunks


def embed(text: str):
    response = openai_client.embeddings.create(model=EMBEDDING_MODEL, input=text)
    return response.data[0].embedding


def ingest_file(path: Path):
    text = path.read_text(encoding="utf-8")
    chunks = chunk_text(text)
    vectors = []
    for i, chunk in enumerate(chunks):
        chunk_id = hashlib.md5(f"{path}:{i}".encode()).hexdigest()
        vectors.append({
            "id": chunk_id,
            "values": embed(chunk),
            "metadata": {
                "source": str(path),
                "chunk_index": i,
                "text": chunk[:500],
            },
        })
    index.upsert(vectors=vectors)
    print(f"Ingested {path.name}: {len(chunks)} chunks")


def main():
    if len(sys.argv) < 2:
        print("Usage: pinecone_ingest.py <file_or_folder>")
        sys.exit(1)

    target = Path(sys.argv[1])
    if target.is_file():
        ingest_file(target)
    elif target.is_dir():
        for md_file in target.rglob("*.md"):
            ingest_file(md_file)
    else:
        print(f"Not found: {target}")
        sys.exit(1)


if __name__ == "__main__":
    main()
