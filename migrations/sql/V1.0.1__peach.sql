-- Flyway migration V1.0.1: Create PIES (Process Information Exchange Schema) and audit schemas
-- This migration creates the audit and pies schemas with their associated tables, functions, triggers, and indexes

-- Create schemas
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS pies;

-- Create audit function
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS trigger AS $body$
    DECLARE
      v_old_data json;
      v_new_data json;

    BEGIN
      if (TG_OP = 'UPDATE') then
        v_old_data := row_to_json(OLD);
        v_new_data := row_to_json(NEW);
        insert into audit.logged_actions ("schema_name", "table_name", "db_user", "updated_by_username", "action_timestamp", "action", "original_data", "new_data")
        values (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, SESSION_USER::TEXT, NEW."updated_by", now(), TG_OP::TEXT, v_old_data, v_new_data);
        RETURN NEW;
      elsif (TG_OP = 'DELETE') then
        v_old_data := row_to_json(OLD);
        insert into audit.logged_actions ("schema_name", "table_name", "db_user", "action_timestamp", "action", "original_data")
        values (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, SESSION_USER::TEXT, now(), TG_OP::TEXT, v_old_data);
        RETURN OLD;
      else
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %', TG_OP, now();
        RETURN NULL;
      end if;

    EXCEPTION
      WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
      WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
      WHEN others THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;

    END;
    $body$
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = pg_catalog, audit;

-- Create updated_at function
CREATE OR REPLACE FUNCTION pies.set_updated_at_func()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
    BEGIN
      new."updated_at" = now();
      RETURN new;
    END;
    $$;

-- Create audit.logged_actions table
CREATE TABLE audit.logged_actions (
    id SERIAL PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    db_user TEXT NOT NULL,
    updated_by_username TEXT,
    action_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    action TEXT NOT NULL,
    original_data JSON,
    new_data JSON
);

-- Create indexes for audit.logged_actions
CREATE INDEX logged_actions_schema_name_idx ON audit.logged_actions (schema_name);
CREATE INDEX logged_actions_table_name_idx ON audit.logged_actions (table_name);
CREATE INDEX logged_actions_action_timestamp_idx ON audit.logged_actions (action_timestamp);
CREATE INDEX logged_actions_action_idx ON audit.logged_actions (action);

-- Create pies.system table
CREATE TABLE pies.system (
    id TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT,
    updated_by TEXT
);

-- Create updated_at trigger for pies.system
CREATE TRIGGER system_set_updated_at_trigger
    BEFORE UPDATE ON pies.system
    FOR EACH ROW
    EXECUTE FUNCTION pies.set_updated_at_func();

-- Create audit trigger for pies.system
CREATE TRIGGER system_audit_trigger
    AFTER UPDATE OR DELETE ON pies.system
    FOR EACH ROW
    EXECUTE FUNCTION audit.if_modified_func();

-- Create pies.transaction table
CREATE TABLE pies.transaction (
    id UUID PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT,
    updated_by TEXT
);

-- Create updated_at trigger for pies.transaction
CREATE TRIGGER transaction_set_updated_at_trigger
    BEFORE UPDATE ON pies.transaction
    FOR EACH ROW
    EXECUTE FUNCTION pies.set_updated_at_func();

-- Create audit trigger for pies.transaction
CREATE TRIGGER transaction_audit_trigger
    AFTER UPDATE OR DELETE ON pies.transaction
    FOR EACH ROW
    EXECUTE FUNCTION audit.if_modified_func();

-- Create pies.version table
CREATE TABLE pies.version (
    id TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT,
    updated_by TEXT
);

-- Create updated_at trigger for pies.version
CREATE TRIGGER version_set_updated_at_trigger
    BEFORE UPDATE ON pies.version
    FOR EACH ROW
    EXECUTE FUNCTION pies.set_updated_at_func();

-- Create audit trigger for pies.version
CREATE TRIGGER version_audit_trigger
    AFTER UPDATE OR DELETE ON pies.version
    FOR EACH ROW
    EXECUTE FUNCTION audit.if_modified_func();

-- Create pies.coding table
CREATE TABLE pies.coding (
    id SERIAL PRIMARY KEY,
    code TEXT NOT NULL,
    code_system TEXT NOT NULL,
    version_id TEXT NOT NULL REFERENCES pies.version(id) ON UPDATE CASCADE ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT,
    updated_by TEXT,
    CONSTRAINT coding_code_code_system_version_id_unique UNIQUE (code, code_system, version_id)
);

-- Create index for pies.coding
CREATE INDEX coding_code_idx ON pies.coding (code);

-- Create updated_at trigger for pies.coding
CREATE TRIGGER coding_set_updated_at_trigger
    BEFORE UPDATE ON pies.coding
    FOR EACH ROW
    EXECUTE FUNCTION pies.set_updated_at_func();

-- Create audit trigger for pies.coding
CREATE TRIGGER coding_audit_trigger
    AFTER UPDATE OR DELETE ON pies.coding
    FOR EACH ROW
    EXECUTE FUNCTION audit.if_modified_func();

-- Create pies.record_kind table
CREATE TABLE pies.record_kind (
    id SERIAL PRIMARY KEY,
    kind TEXT NOT NULL,
    version_id TEXT NOT NULL REFERENCES pies.version(id) ON UPDATE CASCADE ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT,
    updated_by TEXT,
    CONSTRAINT record_kind_version_id_kind_unique UNIQUE (version_id, kind)
);

-- Create updated_at trigger for pies.record_kind
CREATE TRIGGER record_kind_set_updated_at_trigger
    BEFORE UPDATE ON pies.record_kind
    FOR EACH ROW
    EXECUTE FUNCTION pies.set_updated_at_func();

-- Create audit trigger for pies.record_kind
CREATE TRIGGER record_kind_audit_trigger
    AFTER UPDATE OR DELETE ON pies.record_kind
    FOR EACH ROW
    EXECUTE FUNCTION audit.if_modified_func();

-- Create pies.system_record table
CREATE TABLE pies.system_record (
    id SERIAL PRIMARY KEY,
    system_id TEXT NOT NULL REFERENCES pies.system(id) ON UPDATE CASCADE ON DELETE CASCADE,
    record_id TEXT NOT NULL,
    record_kind_id INTEGER NOT NULL REFERENCES pies.record_kind(id) ON UPDATE CASCADE ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT,
    updated_by TEXT,
    CONSTRAINT system_record_system_id_record_id_unique UNIQUE (system_id, record_id)
);

-- Create indexes for pies.system_record
CREATE INDEX system_record_record_id_idx ON pies.system_record (record_id);
CREATE INDEX system_record_system_id_idx ON pies.system_record (system_id);

-- Create updated_at trigger for pies.system_record
CREATE TRIGGER system_record_set_updated_at_trigger
    BEFORE UPDATE ON pies.system_record
    FOR EACH ROW
    EXECUTE FUNCTION pies.set_updated_at_func();

-- Create audit trigger for pies.system_record
CREATE TRIGGER system_record_audit_trigger
    AFTER UPDATE OR DELETE ON pies.system_record
    FOR EACH ROW
    EXECUTE FUNCTION audit.if_modified_func();

-- Create pies.process_event table
CREATE TABLE pies.process_event (
    id SERIAL PRIMARY KEY,
    transaction_id UUID NOT NULL REFERENCES pies.transaction(id) ON UPDATE CASCADE ON DELETE CASCADE,
    system_record_id INTEGER NOT NULL REFERENCES pies.system_record(id) ON UPDATE CASCADE ON DELETE CASCADE,
    start_date DATE NOT NULL,
    start_time TIMETZ,
    end_date DATE,
    end_time TIMETZ,
    coding_id INTEGER NOT NULL REFERENCES pies.coding(id) ON UPDATE CASCADE ON DELETE CASCADE,
    status TEXT,
    status_code TEXT,
    status_description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT,
    updated_by TEXT
);

-- Create index for pies.process_event
CREATE INDEX process_event_system_record_id_idx ON pies.process_event (system_record_id);

-- Create updated_at trigger for pies.process_event
CREATE TRIGGER process_event_set_updated_at_trigger
    BEFORE UPDATE ON pies.process_event
    FOR EACH ROW
    EXECUTE FUNCTION pies.set_updated_at_func();

-- Create audit trigger for pies.process_event
CREATE TRIGGER process_event_audit_trigger
    AFTER UPDATE OR DELETE ON pies.process_event
    FOR EACH ROW
    EXECUTE FUNCTION audit.if_modified_func();

-- Create pies.record_linkage table
CREATE TABLE pies.record_linkage (
    id SERIAL PRIMARY KEY,
    transaction_id UUID NOT NULL UNIQUE REFERENCES pies.transaction(id) ON UPDATE CASCADE ON DELETE CASCADE,
    system_record_id INTEGER NOT NULL REFERENCES pies.system_record(id) ON UPDATE CASCADE ON DELETE CASCADE,
    linked_system_record_id INTEGER NOT NULL REFERENCES pies.system_record(id) ON UPDATE CASCADE ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT,
    updated_by TEXT,
    CONSTRAINT record_linkage_forward_unique UNIQUE (system_record_id, linked_system_record_id),
    CONSTRAINT record_linkage_reverse_unique UNIQUE (linked_system_record_id, system_record_id)
);

-- Create indexes for pies.record_linkage
CREATE INDEX record_linkage_system_record_id_idx ON pies.record_linkage (system_record_id);
CREATE INDEX record_linkage_linked_system_record_id_idx ON pies.record_linkage (linked_system_record_id);

-- Create updated_at trigger for pies.record_linkage
CREATE TRIGGER record_linkage_set_updated_at_trigger
    BEFORE UPDATE ON pies.record_linkage
    FOR EACH ROW
    EXECUTE FUNCTION pies.set_updated_at_func();

-- Create audit trigger for pies.record_linkage
CREATE TRIGGER record_linkage_audit_trigger
    AFTER UPDATE OR DELETE ON pies.record_linkage
    FOR EACH ROW
    EXECUTE FUNCTION audit.if_modified_func();
