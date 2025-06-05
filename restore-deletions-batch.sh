#!/bin/bash
# Script to restore deleted S3 objects from specific dates

# Get a list of all delete markers for the specified prefix and date range
aws s3api list-object-versions \
    --bucket wordpress-protected-s3-assets-prod-assets \
    --prefix original_media/www.bu.edu/ \
    --query "DeleteMarkers[?starts_with(LastModified, '2025-06-02') || starts_with(LastModified, '2025-06-03')]" \
    --output json > delete-markers.json

# Count total number of objects to process
total_objects=$(jq 'length' delete-markers.json)
echo "Total objects to process: $total_objects"

# Process delete markers in batches of 1000
batch_size=1000
start_index=0

while [ $start_index -lt $total_objects ]; do
    echo "Processing batch starting at index $start_index..."
    
    # Create a batch of up to 1000 objects
    jq -c "{
        Objects: [.[$start_index:$(($start_index + $batch_size))] | .[] | {Key: .Key, VersionId: .VersionId}],
        Quiet: false
    }" delete-markers.json > objects-to-delete.json
    
    # Process this batch
    echo "Restoring files in current batch..."
    aws s3api delete-objects \
        --no-cli-pager \
        --bucket wordpress-protected-s3-assets-prod-assets \
        --delete file://objects-to-delete.json \
        || echo "Some restorations may have failed in this batch, check output above"
    
    # Move to next batch
    start_index=$(($start_index + $batch_size))
    
    # Small delay to avoid rate limiting
    sleep 1
done

# Clean up temporary file
rm objects-to-delete.json
echo "All batches processed"

