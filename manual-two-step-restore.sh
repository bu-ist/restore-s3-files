

aws s3api list-object-versions \
    --bucket wordpress-protected-s3-assets-prod-assets \
    --prefix original_media/www.bu.edu/cura/ \
    --query "DeleteMarkers[?starts_with(LastModified, '2025-06-02') || starts_with(LastModified, '2025-06-03')]" \
    --output json > delete-markers.json



# Process each delete marker and remove it to restore the original files
cat delete-markers.json | \
    jq -r '.[] | [.Key, .VersionId] | @tsv' | \
    while IFS=$'\t' read -r Key VersionId; do
        echo "Restoring: $Key"
        aws s3api delete-object \
            --bucket wordpress-protected-s3-assets-prod-assets \
            --key "$Key" \
            --version-id "$VersionId" || echo "Failed to restore: $Key"
    done

