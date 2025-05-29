# Clean up failed attempts
python3 -mvenv venv
source venv/bin/activate

# Download the official Microsoft mobile-optimized ONNX model
pip install huggingface_hub

# Download the mobile-optimized version
python - << 'EOF'
from huggingface_hub import snapshot_download

print("📥 Downloading official Microsoft Phi-3-mini ONNX model...")
print("🎯 This is pre-optimized for mobile/CPU inference")

# Download the mobile-optimized ONNX model
snapshot_download(
    repo_id="microsoft/Phi-3-mini-4k-instruct-onnx",
    allow_patterns=["cpu_and_mobile/*"],
    local_dir="phi3_official",
    local_dir_use_symlinks=False
)

print("✅ Download complete!")
print("📁 Files are in: phi3_official/cpu_and_mobile/")

# List what was downloaded
import os
mobile_dir = "phi3_official/cpu_and_mobile"
if os.path.exists(mobile_dir):
    for root, dirs, files in os.walk(mobile_dir):
        for file in files:
            full_path = os.path.join(root, file)
            size_mb = os.path.getsize(full_path) / (1024**2)
            print(f"  📄 {os.path.relpath(full_path, mobile_dir)}: {size_mb:.1f}MB")
            
print("\n🎉 Ready for iPhone 16e integration!")
EOF

mv -f ./cpu-int4-rtn-block-32-acc-level-4{,.old}
mv phi3_official/cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4 .
rm -rf phi3_official
