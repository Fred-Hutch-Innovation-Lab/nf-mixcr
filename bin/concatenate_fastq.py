#!/usr/bin/env python3
import shutil
import os
import re
import argparse
from collections import defaultdict

def get_args():
    parser = argparse.ArgumentParser(description='Concatenate multiple FASTQs into one, grouping by read type and sample. Intended for use with files from multiple lanes or runs.')
    parser.add_argument('--files', nargs='+', required=True, help='List of input files to concatenate')
    parser.add_argument('--output', required=True, help='Output directory')
    parser.add_argument('--sampleID', required=True, help='Prefix for output files')
    # parser.add_argument('--sample_id_pattern', default='.+?', help='Regex pattern for matching sample IDs (defalut: .+?)')
    parser.add_argument('--copy_method', choices=['symlink', 'copy'], default='symlink', help='Method to handle lone files (default: copy)')
    args = parser.parse_args()
    return args

def concatenate_files_shutil(file_list, output_file):
    with open(output_file, 'wb') as outfile:
        for filename in file_list:
            with open(filename, 'rb') as infile:
                shutil.copyfileobj(infile, outfile)

def group_files(file_list): 
    grouped_files = defaultdict(list)
    pattern = re.compile(
        # rf"(?P<id>{sample_id_pattern})?(?:_S\d+)?_(?P<read>[IR][12])_?(?P<lane>\d+)?"
        r"(?P<id>.+?)?(?:_S\d+)?_(?P<read>[IR][12])_?(?P<lane>\d+)?"
    )
    for file in file_list:
        match = re.search(pattern, os.path.basename(file))
        # print(match.group('id'), match.group('read'), match.group('lane'))
        if match:
            # file_id = match.group('id')
            read_type = match.group('read')
            # lane = match.group('lane') if match.group('lane') else '1'
            key = read_type
            grouped_files[key].append(file)
    return grouped_files

def main():
    args = get_args()
    grouped_files = group_files(args.files)
    for key, files in grouped_files.items():
        outfile = os.path.join(args.output, f"{args.sampleID}_{key}.fastq.gz")
        if len(files) > 1:
            print(f"Concatenating {len(files)} files ({[os.path.basename(f) for f in files]}) to {outfile}")
            concatenate_files_shutil(files, outfile)
        else:
            if args.copy_method == 'copy':
                shutil.copy(files[0], outfile)
            elif args.copy_method == 'symlink':
                os.symlink(files[0], outfile)

if __name__ == '__main__':
    main()