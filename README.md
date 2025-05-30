This App implements the Phi3 LLM inference model on late model iPhones and iPads in an offline mode. Therefore it bypasses privacy and network
availability concerns. The initial install is large (2.5GB) but uses no network bandwidth once loaded. Suitable for iPhones such as the 16e with
8GB of RAM and hardware AI inference engine. Some limited functionality on lesser models.

Most users will want to install from the App Store (subject to successful review). But to build from source and/or customise for a different model
you would follow the following procedure:

git clone https://github.com/jrrk2/Phi3iOS.git
cd Phi3iOS
./download_onnx.bash 
git submodule update --init --recursive
open Phi3iOS.xcodeproj
Update signing Team and Bundle Identifier as needed. Apple-B to build. Apple-R to run.

Unless you are a project collaborator, you will need to adjust paths of sub-repositories, for example

git@github.com:jrrk2/onnxruntime-genai.git becomes https://github.com/jrrk2/onnxruntime-genai.git

If you don't know how to do that, consult AI!

![screenshot1](https://github.com/user-attachments/assets/915d491e-a8bc-415c-afea-60472cc98750)
![screenshot2](https://github.com/user-attachments/assets/a16eb3df-20bc-48ad-b672-45b5504115e1)
<img width="1024" alt="ipad" src="https://github.com/user-attachments/assets/719cd964-2612-46db-9962-4a5ae2026972" />
