terraform {
  cloud {
    organization = "liwich"
    
    workspaces {
      name = "infrastructure-dev"
    }
  }
  
}
