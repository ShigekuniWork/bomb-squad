-- +goose Up

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

-- The application sets this value with set_config(..., true) inside each transaction.
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants FORCE ROW LEVEL SECURITY;
CREATE POLICY tenants_tenant_isolation ON tenants
    USING (id = current_setting('app.current_tenant_id', true)::uuid)
    WITH CHECK (id = current_setting('app.current_tenant_id', true)::uuid);

ALTER TABLE tenant_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_memberships FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_memberships_tenant_isolation ON tenant_memberships
    USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid)
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;
CREATE POLICY users_tenant_isolation ON users
    USING (EXISTS (
        SELECT 1
        FROM tenant_memberships
        WHERE tenant_memberships.user_id = users.id
          AND tenant_memberships.tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ))
    WITH CHECK (EXISTS (
        SELECT 1
        FROM tenant_memberships
        WHERE tenant_memberships.user_id = users.id
          AND tenant_memberships.tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ));

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations FORCE ROW LEVEL SECURITY;
CREATE POLICY organizations_tenant_isolation ON organizations
    USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid)
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

ALTER TABLE organization_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_memberships FORCE ROW LEVEL SECURITY;
CREATE POLICY organization_memberships_tenant_isolation ON organization_memberships
    USING (organization_id IN (
        SELECT id
        FROM organizations
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ) AND user_id IN (
        SELECT user_id
        FROM tenant_memberships
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ))
    WITH CHECK (organization_id IN (
        SELECT id
        FROM organizations
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ) AND user_id IN (
        SELECT user_id
        FROM tenant_memberships
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ));

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects FORCE ROW LEVEL SECURITY;
CREATE POLICY projects_tenant_isolation ON projects
    USING (organization_id IN (
        SELECT id
        FROM organizations
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ))
    WITH CHECK (organization_id IN (
        SELECT id
        FROM organizations
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ));

ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams FORCE ROW LEVEL SECURITY;
CREATE POLICY teams_tenant_isolation ON teams
    USING (organization_id IN (
        SELECT id
        FROM organizations
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ))
    WITH CHECK (organization_id IN (
        SELECT id
        FROM organizations
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ));

ALTER TABLE project_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_teams FORCE ROW LEVEL SECURITY;
CREATE POLICY project_teams_tenant_isolation ON project_teams
    USING (organization_id IN (
        SELECT id
        FROM organizations
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ))
    WITH CHECK (organization_id IN (
        SELECT id
        FROM organizations
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ));

ALTER TABLE project_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_memberships FORCE ROW LEVEL SECURITY;
CREATE POLICY project_memberships_tenant_isolation ON project_memberships
    USING (project_id IN (
        SELECT p.id
        FROM projects p
        JOIN organizations o ON o.id = p.organization_id
        WHERE o.tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ) AND user_id IN (
        SELECT user_id
        FROM tenant_memberships
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ))
    WITH CHECK (project_id IN (
        SELECT p.id
        FROM projects p
        JOIN organizations o ON o.id = p.organization_id
        WHERE o.tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ) AND user_id IN (
        SELECT user_id
        FROM tenant_memberships
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ));

ALTER TABLE team_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_memberships FORCE ROW LEVEL SECURITY;
CREATE POLICY team_memberships_tenant_isolation ON team_memberships
    USING (team_id IN (
        SELECT t.id
        FROM teams t
        JOIN organizations o ON o.id = t.organization_id
        WHERE o.tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ) AND user_id IN (
        SELECT user_id
        FROM tenant_memberships
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ))
    WITH CHECK (team_id IN (
        SELECT t.id
        FROM teams t
        JOIN organizations o ON o.id = t.organization_id
        WHERE o.tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ) AND user_id IN (
        SELECT user_id
        FROM tenant_memberships
        WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    ));

-- +goose Down

DROP TABLE team_memberships;
DROP TABLE project_memberships;
DROP TABLE project_teams;
DROP TABLE teams;
DROP TABLE projects;
DROP TABLE organization_memberships;
DROP TABLE organizations;
DROP TABLE tenant_memberships;
DROP TABLE users;
DROP TABLE tenants;
