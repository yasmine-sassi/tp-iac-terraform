# 1. Init — télécharge le provider kreuzwerker/docker

terraform init

# 2. Plan — simulation, aucun changement réel

terraform plan

# 3. Apply — crée les 4 ressources (2 images + 2 conteneurs)

terraform apply -auto-approve

# 4. Validation

curl http://localhost:8080/
docker ps | grep tp-

# 5. Destroy — nettoie tout, vide le tfstate

terraform destroy -auto-approve
