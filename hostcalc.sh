#!/bin/bash

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validate IP or subnet
is_valid_ip_or_subnet() {
    local input=$1
    if [[ $input =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to calculate the number of hosts in a subnet using ipcalc
calculate_hosts_for_subnet() {
    local subnet=$1
    local host_count=$(ipcalc "$subnet" | grep 'Hosts/Net:' | awk '{print $2}')
    echo "$host_count"
}

# Function to calculate the number of IPs in a range
calculate_hosts_for_range() {
    local range=$1
    local lower_bound=$(echo $range | cut -d '-' -f 1)
    local upper_bound=$(echo $range | cut -d '-' -f 2)
    local lower_octet=$(echo $lower_bound | cut -d '.' -f 4)
    local upper_octet=$(echo $upper_bound | cut -d '.' -f 4)
    local host_count=$((upper_octet - lower_octet + 1))
    echo "$host_count"
}

# Determine the type of input (single IP, range, or subnet) and calculate hosts
calculate_hosts() {
    local input=$1

    if grep -qE '/' <<< "$input"; then
        # Subnet
        host_count=$(calculate_hosts_for_subnet "$input")
        echo "$host_count"
    elif grep -qE '-' <<< "$input"; then
        # Range
        host_count=$(calculate_hosts_for_range "$input")
        echo "$host_count"
    else
        # Single IP
        echo "1"
    fi
}

# Process a file or a single input
# Process a file or a single input
process_input() {
    local input=$1
    local total_hosts=0

    if [ -f "$input" ]; then
        # File input
        echo -e "${BLUE}Processing from file: $input${NC}"
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                host_count=$(calculate_hosts "$line")
                total_hosts=$((total_hosts + host_count))
                if grep -qE '/' <<< "$line"; then
                    echo -e "${YELLOW}Subnet $line: ${GREEN}$host_count${NC}"
                elif grep -qE '-' <<< "$line"; then
                    echo -e "${YELLOW}Range $line: ${GREEN}$host_count${NC}"
                else
                    echo -e "${YELLOW}Host $line: ${GREEN}$host_count${NC}"
                fi
            fi
        done < "$input"
    elif is_valid_ip_or_subnet "$input"; then
        # Single input
        host_count=$(calculate_hosts "$input")
        total_hosts=$((total_hosts + host_count))
        if grep -qE '/' <<< "$input"; then
            echo -e "${YELLOW}Subnet $input: ${GREEN}$host_count${NC}"
        elif grep -qE '-' <<< "$input"; then
            echo -e "${YELLOW}Range $input: ${GREEN}$host_count${NC}"
        else
            echo -e "${YELLOW}Host $input: ${GREEN}$host_count${NC}"
        fi
    else
        echo -e "${RED}Invalid input. Please provide a valid IP, subnet, or file.${NC}"
        exit 1
    fi

    echo -e "${RED}Total Hosts across all processed inputs: ${GREEN}$total_hosts${NC}"
}

# Main script execution
if [ "$#" -ne 1 ]; then
    echo -e "${RED}Usage: $0 <subnet/range/IP or file>${NC}"
    exit 1
fi

process_input "$1"
echo -e "${BLUE}Happy hacking :)${NC}"

