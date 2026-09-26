-- name: GetTenant :one
SELECT id, created_at, updated_at, name, slug
FROM tenants
WHERE id = $1;

-- name: CreateTenant :one
INSERT INTO tenants (name, slug)
VALUES ($1, $2)
RETURNING id, created_at, updated_at, name, slug;
