#!/usr/bin/env python3
"""
Pinecone query. Stratos Memory Stack, layer 4.

Usage:
    python3 pinecone_query.py "your question" --top-k 3
    python3 pinecone_query.py "what does the playbook say about pricing"

Requires:
    pip install pinecone-client openai python-dotenv
    .env file with PINECONE_API_KEY and OPENAI_API_KEY

Output:
    Top-k matching chunks with source path and similarity score.
"""

import os
import sys
import argparse
from dotenv import load_dotenv
from pinecone import Pinecone
from openai import OpenAI

load_dotenv()

INDEX_NAME = "your-vault"
EMBEDDING_MODEL = "text-embedding-3-small"

pc = Pinecone(api_key=os.environ["PINECONE_API_KEY"])
openai_client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
index = pc.Index(INDEX_NAME)


def embed(text: str):
    response = openai_client.embeddings.create(model=EMBEDDING_MODEL, input=text)
    return response.data[0].embedding


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("query", help="Question or topic to search")
    parser.add_argument("--top-k", type=int, default=3, help="Number of matches to return")
    args = parser.parse_args()

    vector = embed(args.query)
    results = index.query(vector=vector, top_k=args.top_k, include_metadata=True)

    print(f"\nQuery: {args.query}\n")
    print(f"Top {args.top_k} matches:\n")

    for i, match in enumerate(results["matches"], 1):
        meta = match["metadata"]
        print(f"--- Match {i} (score: {match['score']:.3f}) ---")
        print(f"Source: {meta['source']}")
        print(f"Chunk: {meta['chunk_index']}")
        print(f"Preview: {meta['text']}")
        print()


if __name__ == "__main__":
    main()
