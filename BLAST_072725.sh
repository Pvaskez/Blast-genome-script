#!/bin/bash

#### Section 1: Makeblastdb and Blastn #### 

gene_file=$(ls *gene*.fasta 2>/dev/null | head -n 1)
if [[ ! -f "$gene_file" ]]; then
    echo "Gene file not found. Exiting."
    exit 1
fi

# Loop through each genome file
for genome_file in *genome*.fasta; do
    [[ -f "$genome_file" ]] || continue  # Skip if no matching files

    # Extract base name without extension
    base_name="${genome_file%%.*}"

    # Create output folder
    mkdir -p "$base_name"

    echo "Running BLAST for genome file: $genome_file"

    # Create BLAST database
    makeblastdb -in "$genome_file" -parse_seqids -dbtype nucl 

    # Run BLAST
    blastn -query "$gene_file" -db "$genome_file" -out "${base_name}/BLAST_OUTPUT.txt" -outfmt 6 

    #### Section 2: Filter Files #### 

    INPUT_FILE="${base_name}/BLAST_OUTPUT.txt" 
    OUTPUT_FILE="${base_name}/BLAST_FILTERED.txt"

    awk -F '\t' '$3 > 70' "$INPUT_FILE" > "$OUTPUT_FILE"

    echo "Filtering hits in: $INPUT_FILE"
    
    awk -F '\t' '$8 > 1600 {print $2}' "$OUTPUT_FILE" > "${base_name}/CONTIG_ID.txt"

    contig_list=$(tr '\n' ',' < "${base_name}/CONTIG_ID.txt" | sed 's/,$//')
    echo "Contigs: $contig_list"

    #### Section 3: Retrieve and Combine FASTA Sequences ####

    combined_fasta="${base_name}/retrieved_sequences.fasta"
    > "$combined_fasta"  # Clear file if it exists

    while IFS= read -r id; do 
        blastdbcmd -db "$genome_file" -entry "$id" >> "$combined_fasta"
    done < "${base_name}/CONTIG_ID.txt"

    echo "Retrieved sequences saved to: $combined_fasta"

    #### Section 4: Clean Up BLAST DB files ####

    rm -f "${genome_file}".n?? "${genome_file}".nal 2>/dev/null

    echo "Finished processing $genome_file"
    echo "Output saved in folder: $base_name"
    echo "-----------------------------------------"
done

echo "BLAST and Retrieval script completed successfully."
exit 0
