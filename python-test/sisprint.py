import pandas as pd
import json
import argparse
from typing import Optional, Dict, Any

def safe_get(data: Dict[str, Any], *keys: str, default: Any = '') -> Any:
    """Safely get nested dictionary values with multiple fallbacks"""
    current = data
    for key in keys:
        if isinstance(current, dict):
            current = current.get(key)
        else:
            return default
        if current is None:
            return default
    return current if current is not None else default

def load_json_data(json_path: str) -> list:
    """Load JSON data and extract book information with safe field access"""
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        raise ValueError(f"Error loading JSON file: {e}")

    books = []
    for main_id, book_list in data.items():
        for book in book_list:
            # Safely handle all fields with potential null/undefined values
            first_mms = ''
            first_signature = ''
            
            nalezeno = book.get('nalezeno')
            if nalezeno and isinstance(nalezeno, list) and len(nalezeno) > 0:
                first_found = nalezeno[0]
                first_mms = str(safe_get(first_found, 'mms', default=''))
                if first_mms:
                    first_signature = find_signature_for_mms(first_mms)

            books.append({
                'ID': main_id,
                'Author': format_authors(safe_get(book, 'autori')),
                'Title': safe_get(book, 'nazev_knihy'),
                'Publisher': safe_get(book, 'vydavatel'),
                'Year': safe_get(book, 'rok_vydani'),
                'Location': safe_get(book, 'misto_vydani'),
                'Other': safe_get(book, 'dalsi_udaje', 'edice'),
                'ISBN': safe_get(book, 'isbn'),
                'Link': safe_get(book, 'online_link'),
                'First_MMS': first_mms,
                'First_Signature': first_signature,
                'RawData': book  # Keep original data for debugging
            })
    return books

def find_signature_for_mms(mms: str) -> Optional[str]:
    """Find signature in Excel file for given MMS"""
    if not mms:
        return None
    
    if not hasattr(find_signature_for_mms, 'signature_map'):
        # Initialize signature map only once
        find_signature_for_mms.signature_map = {}
        try:
            if args.excel_file:
                df = pd.read_excel(args.excel_file)
                if 'mms' in df.columns and 'signatura' in df.columns:
                    df['mms'] = df['mms'].astype(str).str.strip()
                    find_signature_for_mms.signature_map = dict(
                        zip(df['mms'], df['signatura']))
        except Exception as e:
            print(f"Warning: Could not load signature data - {e}")
    
    return find_signature_for_mms.signature_map.get(str(mms).strip())

def format_authors(authors) -> str:
    """Safely format authors list into a string"""
    if not authors:
        return ''
    
    try:
        if isinstance(authors, list):
            author_strings = []
            for author in authors:
                if isinstance(author, dict):
                    first = safe_get(author, 'first_names', default='').strip()
                    last = safe_get(author, 'last_name', default='').strip()
                    if first or last:
                        author_strings.append(f"{first} {last}".strip())
            return ', '.join(author_strings) if author_strings else ''
        return str(authors)
    except Exception:
        return ''

def deduplicate_books(books: list) -> list:
    """Deduplicate books and combine IDs with enhanced safety"""
    book_dict = {}
    
    for book in books:
        # Create a composite key that's safe with potential missing fields
        key = (
            str(safe_get(book, 'Title')).lower().strip(),
            str(safe_get(book, 'Author')).lower().strip()
        )
        
        if key in book_dict:
            # Combine IDs
            existing = book_dict[key]
            existing['ID'] = f"{existing['ID']}, {book['ID']}"
            
            # Keep first non-empty signature
            if not existing['First_Signature'] and book['First_Signature']:
                existing['First_Signature'] = book['First_Signature']
                existing['First_MMS'] = book['First_MMS']
        else:
            book_dict[key] = book.copy()
    
    return list(book_dict.values())

def main():
    global args
    parser = argparse.ArgumentParser(description='Process JSON book data with robust null handling')
    parser.add_argument('json_file', help='Path to input JSON file')
    parser.add_argument('excel_file', help='Path to Excel file with signature data')
    parser.add_argument('output_file', help='Path for output Excel file')
    args = parser.parse_args()

    try:
        print("Processing data...")
        books = load_json_data(args.json_file)
        deduplicated = deduplicate_books(books)
        
        df = pd.DataFrame(deduplicated)
        output_columns = ['ID', 'Author', 'Title', 'Publisher', 'Year', 
                        'Location', 'ISBN', 'Link', 'Other', 'First_Signature', 'First_MMS']
        
        # Ensure all columns exist (protect against missing data)
        for col in output_columns:
            if col not in df.columns:
                df[col] = ''
        
        df[output_columns].to_excel(args.output_file, index=False)
        print(f"Successfully saved {len(deduplicated)} records to {args.output_file}")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    import sys
    main()
