terraform {
  cloud {
    organization = "liwich"
    
    workspaces {
      name = "infrastructure-prod"
    }
  }
  
}
