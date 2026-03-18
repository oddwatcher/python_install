#!/bin/bash

set -e

# Check nvidia-smi
if ! command -v nvidia-smi &> /dev/null; then
    echo "Error: nvidia-smi not found. Install NVIDIA drivers first."
    exit 1
fi

# Extract CUDA driver version
cuda_driver=$(nvidia-smi | grep "CUDA Version" | awk '{print $9}')
if [ -z "$cuda_driver" ]; then
    cuda_driver=$(nvidia-smi | grep -oP 'CUDA Version: \K[0-9]+\.[0-9]+')
fi

if [ -z "$cuda_driver" ]; then
    echo "Error: Cannot detect CUDA version"
    exit 1
fi

echo "Driver CUDA Version: $cuda_driver"

# Convert to comparable integer (12.4 -> 124)
driver_int=$(echo "$cuda_driver" | tr -d '.')

# Fetch available PyTorch CUDA versions dynamically
echo "Fetching available PyTorch CUDA versions..."
if ! available_cus=$(curl -s --max-time 10 https://download.pytorch.org/whl/ | \
    grep -oE 'href="cu[0-9]+' | \
    sed 's/href="cu/cu/' | \
    sort -u | \
    sort -r); then
    
    echo "Warning: Failed to fetch PyTorch index"
    available_cus=""
fi

selected_cu=""
if [ -n "$available_cus" ]; then
    # Find highest compatible version
    for cu in $available_cus; do
        cu_num=${cu:2}
        
        # Skip if higher than driver version
        if [ "$cu_num" -gt "$driver_int" ]; then
            continue
        fi
        
        # Verify URL is reachable
        url="https://download.pytorch.org/whl/${cu}"
        if wget --spider --timeout=5 "$url" 2>&1 | grep -qE "200 OK|HTTP/[0-9.]+ 30[12]|403"; then
            selected_cu=$cu
            break
        fi
    done
fi

# Install
echo "Upgrading typing-extensions..."
pip install --upgrade typing-extensions

if [ -n "$selected_cu" ]; then
    echo "Installing PyTorch with CUDA $selected_cu (compatible with driver $cuda_driver)..."
    pip install torch torchvision --index-url "https://download.pytorch.org/whl/${selected_cu}"

    echo "Done. Verify: python -c 'import torch; print(f\"CUDA: {torch.cuda.is_available()}, Ver: {torch.version.cuda}\")'"
else
    echo "No compatible CUDA version found for driver"
fi
