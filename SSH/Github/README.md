# Crear clau pública/privada i assignar clau pública a gitHub
1. Crear clau privada/pública
```
ssh-keygen -t rsa -b 4096 -C "email@email.com"
```
2. Ens asegurem que el ssh-agent està actiu
```
eval $(ssh-agent -s)
```
3. Afegeim la nostra clau privada al gestor. Entorn Windows
```
ssh-add ~/.ssh/id_rsa
```
4. Afegim la clau pública a les **settings** (SSH-Keys) del nostre perfil de gitHub
5. Recorda un clau privada/pública per cada usuari i equip
