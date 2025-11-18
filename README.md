# talleres
# Taller HTTP - Dog API 

## Objetivo
Módulo que consume datos desde una API pública (Dog CEO), mostrando listado y detalle con navegación mediante go_router.

## API utilizada
**Base URL:** https://dog.ceo/api  
**Endpoints:**
- `/breeds/list/all` → Listado de razas
- `/breed/{breed}/images/random` → Imagen aleatoria por raza

## Estructura
```
lib/
  models/          # modelos (Breed)
  services/        # lógica HTTP (DogService)
  routes/          # rutas con go_router
  views/           # pantallas de Listado y Detalle
```

## Estados
- Cargando → `CircularProgressIndicator`
- Éxito → ListView.builder
- Error → mensaje + botón Reintentar
