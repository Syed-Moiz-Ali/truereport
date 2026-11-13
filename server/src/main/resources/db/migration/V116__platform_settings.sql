CREATE TABLE platform_settings (
    setting_key VARCHAR(80) NOT NULL,
    value_json TEXT NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    updated_by VARCHAR(36) NULL,
    CONSTRAINT pk_platform_settings PRIMARY KEY (setting_key)
);
