#!/usr/bin/env python3
"""
Terraform Cloud Workspace Creation Script
Creates projects and workspaces via Terraform Cloud API
"""

import os
import sys
import json
import requests
from typing import Dict, List, Optional

class TerraformCloudAPI:
    def __init__(self, token: str, organization: str):
        self.token = token
        self.organization = organization
        self.base_url = "https://app.terraform.io/api/v2"
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/vnd.api+json"
        }
    
    def validate_token(self) -> bool:
        """Validate the API token"""
        try:
            response = requests.get(
                f"{self.base_url}/account/details",
                headers=self.headers
            )
            return response.status_code == 200
        except Exception as e:
            print(f"Error validating token: {e}")
            return False
    
    def get_or_create_project(self, project_name: str) -> Optional[str]:
        """Get or create a project and return its ID"""
        # List existing projects
        try:
            response = requests.get(
                f"{self.base_url}/organizations/{self.organization}/projects",
                headers=self.headers
            )
            
            if response.status_code == 200:
                projects = response.json().get("data", [])
                for project in projects:
                    if project["attributes"]["name"] == project_name:
                        print(f"✓ Project '{project_name}' already exists")
                        return project["id"]
        except Exception as e:
            print(f"Warning: Error checking existing projects: {e}")
        
        # Create new project
        try:
            payload = {
                "data": {
                    "type": "projects",
                    "attributes": {
                        "name": project_name
                    }
                }
            }
            
            response = requests.post(
                f"{self.base_url}/organizations/{self.organization}/projects",
                headers=self.headers,
                json=payload
            )
            
            if response.status_code == 201:
                project_id = response.json()["data"]["id"]
                print(f"✓ Created project '{project_name}'")
                return project_id
            else:
                print(f"Error creating project: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            print(f"Error creating project: {e}")
            return None
    
    def create_workspace(
        self, 
        workspace_name: str, 
        project_id: str,
        terraform_version: str = "~> 1.6.0",
        auto_apply: bool = False
    ) -> Optional[Dict]:
        """Create a workspace and return its details"""
        # Check if workspace exists
        try:
            response = requests.get(
                f"{self.base_url}/organizations/{self.organization}/workspaces/{workspace_name}",
                headers=self.headers
            )
            
            if response.status_code == 200:
                print(f"✓ Workspace '{workspace_name}' already exists")
                return response.json()["data"]
        except:
            pass
        
        # Create workspace
        payload = {
            "data": {
                "type": "workspaces",
                "attributes": {
                    "name": workspace_name,
                    "terraform-version": terraform_version,
                    "auto-apply": auto_apply,
                    "execution-mode": "local",  # Local execution for CI/CD compatibility with modules
                    "file-triggers-enabled": True,
                    "queue-all-runs": False,
                    "speculative-enabled": True
                },
                "relationships": {
                    "project": {
                        "data": {
                            "type": "projects",
                            "id": project_id
                        }
                    }
                }
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/organizations/{self.organization}/workspaces",
                headers=self.headers,
                json=payload
            )
            
            if response.status_code == 201:
                workspace = response.json()["data"]
                print(f"✓ Created workspace '{workspace_name}'")
                return workspace
            else:
                print(f"Error creating workspace: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            print(f"Error creating workspace: {e}")
            return None
    
    def set_workspace_variables(
        self, 
        workspace_id: str,
        aws_access_key: Optional[str] = None,
        aws_secret_key: Optional[str] = None,
        aws_region: str = "us-east-1"
    ) -> bool:
        """Set environment variables in workspace"""
        variables = []
        
        if aws_access_key:
            variables.append({
                "key": "AWS_ACCESS_KEY_ID",
                "value": aws_access_key,
                "category": "env",
                "sensitive": True
            })
        
        if aws_secret_key:
            variables.append({
                "key": "AWS_SECRET_ACCESS_KEY",
                "value": aws_secret_key,
                "category": "env",
                "sensitive": True
            })
        
        variables.append({
            "key": "AWS_DEFAULT_REGION",
            "value": aws_region,
            "category": "env",
            "sensitive": False
        })
        
        success = True
        for var in variables:
            try:
                payload = {
                    "data": {
                        "type": "vars",
                        "attributes": var
                    }
                }
                
                response = requests.post(
                    f"{self.base_url}/workspaces/{workspace_id}/vars",
                    headers=self.headers,
                    json=payload
                )
                
                if response.status_code == 201:
                    key_display = var["key"] if not var["sensitive"] else f"{var['key']} (sensitive)"
                    print(f"  ✓ Set variable: {key_display}")
                else:
                    # Variable might already exist
                    if "already exists" in response.text.lower():
                        print(f"  - Variable {var['key']} already exists")
                    else:
                        print(f"  ✗ Error setting {var['key']}: {response.status_code}")
                        success = False
            except Exception as e:
                print(f"  ✗ Error setting variable: {e}")
                success = False
        
        return success


def main():
    print("=" * 60)
    print("Terraform Cloud Workspace Setup")
    print("=" * 60)
    
    # Get inputs
    tfc_token = os.environ.get("TFC_TOKEN") or input("Enter Terraform Cloud API Token: ").strip()
    tfc_org = os.environ.get("TFC_ORGANIZATION") or input("Enter Terraform Cloud Organization: ").strip()
    project_name = os.environ.get("TFC_PROJECT") or input("Enter Project Name [infrastructure]: ").strip() or "infrastructure"
    
    # Skip AWS credentials - using OIDC instead
    aws_access_key = None
    aws_secret_key = None
    aws_region = "us-west-2"
    
    # Initialize API client
    print("\n" + "=" * 60)
    print("Initializing Terraform Cloud API...")
    print("=" * 60)
    
    api = TerraformCloudAPI(tfc_token, tfc_org)
    
    # Validate token
    if not api.validate_token():
        print("✗ Invalid Terraform Cloud token")
        sys.exit(1)
    print("✓ Token validated")
    
    # Create or get project
    print(f"\nCreating project '{project_name}'...")
    project_id = api.get_or_create_project(project_name)
    if not project_id:
        print("✗ Failed to create project")
        sys.exit(1)
    
    # Create workspaces for each environment
    environments = ["dev", "staging", "prod"]
    workspaces = {}
    
    print(f"\nCreating workspaces...")
    for env in environments:
        workspace_name = f"{project_name}-{env}"
        workspace = api.create_workspace(
            workspace_name=workspace_name,
            project_id=project_id,
            auto_apply=(env == "dev")  # Auto-apply only for dev
        )
        
        if workspace:
            workspaces[env] = workspace
    
    # Summary
    print("\n" + "=" * 60)
    print("Setup Complete!")
    print("=" * 60)
    print(f"Organization: {tfc_org}")
    print(f"Project: {project_name}")
    print(f"Workspaces created: {len(workspaces)}")
    for env, workspace in workspaces.items():
        print(f"  - {workspace['attributes']['name']}")
    
    # Save configuration
    config = {
        "organization": tfc_org,
        "project": project_name,
        "workspaces": {env: ws["attributes"]["name"] for env, ws in workspaces.items()}
    }
    
    config_file = "../.tfc-config.json"
    with open(config_file, "w") as f:
        json.dump(config, f, indent=2)
    print(f"\n✓ Configuration saved to {config_file}")
    
    print("\n" + "=" * 60)
    print("🎉 Terraform Cloud Workspaces Created!")
    print("=" * 60)
    print("\n📋 Next Steps for GitHub Actions CI/CD:")
    print("\n1️⃣  CREATE TEAM TOKEN:")
    print(f"   • Go to: https://app.terraform.io/app/{tfc_org}/settings/teams")
    print("   • Create team: 'github-actions'")
    print("   • Generate team token (set to 'Never' expire)")
    print("   • Copy the token")
    print("\n2️⃣  GRANT TEAM ACCESS TO WORKSPACES:")
    for env, workspace in workspaces.items():
        ws_name = workspace['attributes']['name']
        print(f"   • {ws_name}: Add 'github-actions' team with 'Write' permission")
    print(f"   • URL: https://app.terraform.io/app/{tfc_org}/workspaces/[workspace]/settings/access")
    print("\n3️⃣  ADD TOKEN TO GITHUB SECRETS:")
    print("   • GitHub repo → Settings → Secrets → Actions")
    print("   • New secret: TF_API_TOKEN")
    print("   • Paste the team token")
    print("\n4️⃣  PUSH YOUR CODE:")
    print("   git push origin main")
    print("   (GitHub Actions will automatically deploy!)")
    print("\n📖 Full guide: docs/TOKEN_MANAGEMENT.md")


if __name__ == "__main__":
    main()
