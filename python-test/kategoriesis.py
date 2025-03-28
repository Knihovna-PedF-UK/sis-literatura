import pandas as pd
import json
import argparse
import sys

def load_json_mms(json_path):
    """Load JSON data and extract all MMS values"""
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        mms_values = set()
        for book_list in data.values():
            for book in book_list:
                for found in book.get('nalezeno', []):
                    if 'mms' in found:
                        mms_values.add(str(found['mms']).strip())
        return mms_values
    except Exception as e:
        print(f"Error loading JSON file: {e}", file=sys.stderr)
        sys.exit(1)

def process_excel(excel_path, output_path, mms_values):
    """Process Excel file and add SIS column"""
    try:
        # Read Excel file
        df = pd.read_excel(excel_path)
        
        # Check if MMS column exists
        if 'mms' not in df.columns:
            print("Error: Input Excel file must contain an 'mms' column", file=sys.stderr)
            sys.exit(1)
        
        # Convert MMS column to string and clean it
        df['mms'] = df['mms'].astype(str).str.strip()
        
        # Add SIS column
        df['SIS'] = df['mms'].apply(lambda x: 'ano' if x in mms_values else 'ne')
        
        # Save to new file
        df.to_excel(output_path, index=False)
        return True
    except Exception as e:
        print(f"Error processing Excel file: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description='Compare Excel table with JSON data and add SIS column indicating MMS matches',
        formatter_class=argparse.RawTextHelpFormatter,
        epilog='''Examples:
  python script.py data.json input.xlsx output.xlsx
  python script.py -j books.json -i library_data.xls -o result.xlsx''')
    
    parser.add_argument('json_file', nargs='?', help='Path to JSON file with book data')
    parser.add_argument('input_excel', nargs='?', help='Path to input Excel file')
    parser.add_argument('output_excel', nargs='?', help='Path for output Excel file')
    
    # Alternative named arguments
    parser.add_argument('-j', '--json', help='JSON file path (alternative to positional)')
    parser.add_argument('-i', '--input', help='Input Excel path (alternative to positional)')
    parser.add_argument('-o', '--output', help='Output Excel path (alternative to positional)')
    
    args = parser.parse_args()
    
    # Determine file paths (priority: named args > positional args)
    json_path = args.json or args.json_file
    input_path = args.input or args.input_excel
    output_path = args.output or args.output_excel
    
    # Verify all paths are provided
    if not all([json_path, input_path, output_path]):
        parser.print_help()
        sys.exit(1)
    
    # Process files
    print(f"Processing files...")
    print(f"JSON data: {json_path}")
    print(f"Input Excel: {input_path}")
    print(f"Output Excel: {output_path}")
    
    mms_set = load_json_mms(json_path)
    if process_excel(input_path, output_path, mms_set):
        print(f"\nSuccess! Output saved to {output_path}")
        print(f"Found {len(mms_set)} unique MMS values in JSON")
        print(f"Sample MMS values: {sorted(mms_set)[:3]}...")  # Show first 3 sorted values

if __name__ == '__main__':
    main()
