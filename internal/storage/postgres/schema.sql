CREATE TABLE tenants (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL,
    slug text NOT NULL UNIQUE
);

CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL
);

CREATE TABLE tenant_memberships (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    tenant_id uuid NOT NULL REFERENCES tenants (id),
    user_id uuid NOT NULL REFERENCES users (id),
    UNIQUE (tenant_id, user_id)
);

CREATE TABLE organizations (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL,
    tenant_id uuid NOT NULL REFERENCES tenants (id),
    UNIQUE (tenant_id, id)
);

CREATE TABLE organization_memberships (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    organization_id uuid NOT NULL REFERENCES organizations (id),
    user_id uuid NOT NULL REFERENCES users (id),
    UNIQUE (organization_id, user_id)
);

CREATE TABLE projects (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL,
    organization_id uuid NOT NULL REFERENCES organizations (id),
    UNIQUE (organization_id, id)
);

CREATE TABLE teams (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL,
    organization_id uuid NOT NULL REFERENCES organizations (id),
    parent_id uuid,
    UNIQUE (organization_id, id),
    FOREIGN KEY (organization_id, parent_id)
        REFERENCES teams (organization_id, id)
);

CREATE TABLE project_teams (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    organization_id uuid NOT NULL REFERENCES organizations (id),
    project_id uuid NOT NULL,
    team_id uuid NOT NULL,
    UNIQUE (project_id, team_id),
    FOREIGN KEY (organization_id, project_id)
        REFERENCES projects (organization_id, id),
    FOREIGN KEY (organization_id, team_id)
        REFERENCES teams (organization_id, id)
);

CREATE TABLE project_memberships (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    project_id uuid NOT NULL REFERENCES projects (id),
    user_id uuid NOT NULL REFERENCES users (id),
    UNIQUE (project_id, user_id)
);

CREATE TABLE team_memberships (
    id uuid PRIMARY KEY DEFAULT uuidv7(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    team_id uuid NOT NULL REFERENCES teams (id),
    user_id uuid NOT NULL REFERENCES users (id),
    UNIQUE (team_id, user_id)
);
