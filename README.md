# How to Run
 - Download this Repo
 - Use *make* without any arguments to initialize terraform structure
 - Use *make validate* to Validate Terraform Project
 - Use *make plan* to plan all terraform actions
 - Use *make apply* to Commit all Changes
 - Use *make destroy* to Destroy all Infrastructure 

## Folder Structure
    ├── Makefile
    ├── main.tf
    ├── modules
    │   ├── Golden_Image
    │   │   ├── main.tf
    │   │   ├── output.tf
    │   │   ├── packer
    │   │   │   ├── golden_image.pkr.hcl
    │   │   │   └── variables.pkr.hcl
    │   │   └── variables.tf
    │   ├── Instances
    │   │   ├── main.tf
    │   │   ├── output.tf
    │   │   └── variables.tf
    │   └── Network
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    └── variables.tf