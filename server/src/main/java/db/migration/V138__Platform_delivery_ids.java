package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

/**
 * Moves delivery requests from the legacy report stack to the clean platform
 * tables.
 *
 * <p>Data decision: <strong>all pre-existing delivery rows are deleted</strong>
 * (children first). Every row written before this migration references
 * {@code inspection_jobs}, {@code report_versions} and
 * {@code public_share_links}; those binaries cannot satisfy the new platform
 * foreign keys without a manual re-map, and the known rows are legacy
 * verification data. Nothing is truncated or silently re-typed: a row that
 * cannot be mapped would have failed the new FK, so it is removed explicitly
 * here. New rows always reference platform ids.</p>
 *
 * <p>Rollback: recreate the legacy binaries is not possible after this delete;
 * restore from backup, then drop the platform foreign keys, convert the columns
 * back to {@code BINARY(16)} with {@code UUID_TO_BIN}, and re-add the legacy
 * constraints.</p>
 */
public class V138__Platform_delivery_ids extends BaseJavaMigration {

    private static final List<String> DELETE_ROWS = List.of(
            "DELETE FROM delivery_webhook_events",
            "DELETE FROM delivery_attempts",
            "DELETE FROM delivery_requests"
    );

    private static final List<String> DROP_LEGACY_FKS_MYSQL = List.of(
            "ALTER TABLE delivery_requests DROP FOREIGN KEY fk_delivery_job",
            "ALTER TABLE delivery_requests DROP FOREIGN KEY fk_delivery_report_version",
            "ALTER TABLE delivery_requests DROP FOREIGN KEY fk_delivery_link"
    );

    private static final List<String> DROP_LEGACY_FKS_OTHER = List.of(
            "ALTER TABLE delivery_requests DROP CONSTRAINT fk_delivery_job",
            "ALTER TABLE delivery_requests DROP CONSTRAINT fk_delivery_report_version",
            "ALTER TABLE delivery_requests DROP CONSTRAINT fk_delivery_link"
    );

    private static final List<String> CONVERT_MYSQL = List.of(
            "ALTER TABLE delivery_requests MODIFY job_id VARCHAR(36) NOT NULL",
            "ALTER TABLE delivery_requests MODIFY report_version_id VARCHAR(36) NOT NULL",
            "ALTER TABLE delivery_requests MODIFY public_share_link_id VARCHAR(36) NULL"
    );

    private static final List<String> CONVERT_OTHER = List.of(
            "ALTER TABLE delivery_requests ALTER COLUMN job_id SET DATA TYPE VARCHAR(36)",
            "ALTER TABLE delivery_requests ALTER COLUMN job_id SET NOT NULL",
            "ALTER TABLE delivery_requests ALTER COLUMN report_version_id SET DATA TYPE VARCHAR(36)",
            "ALTER TABLE delivery_requests ALTER COLUMN report_version_id SET NOT NULL",
            "ALTER TABLE delivery_requests ALTER COLUMN public_share_link_id SET DATA TYPE VARCHAR(36)"
    );

    private static final List<String> ADD_PLATFORM_FKS = List.of(
            "ALTER TABLE delivery_requests ADD CONSTRAINT fk_delivery_platform_job "
                    + "FOREIGN KEY (job_id) REFERENCES platform_jobs (id)",
            "ALTER TABLE delivery_requests ADD CONSTRAINT fk_delivery_platform_report_version "
                    + "FOREIGN KEY (report_version_id) REFERENCES platform_report_versions (id)",
            "ALTER TABLE delivery_requests ADD CONSTRAINT fk_delivery_platform_link "
                    + "FOREIGN KEY (public_share_link_id) REFERENCES platform_public_links (id)"
    );

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        boolean mysql = connection.getMetaData().getDatabaseProductName()
                .toLowerCase().contains("mysql");

        for (String sql : DELETE_ROWS) {
            execute(connection, sql, false);
        }
        for (String sql : mysql ? DROP_LEGACY_FKS_MYSQL : DROP_LEGACY_FKS_OTHER) {
            // Tolerate a partially migrated schema; the conversion below still
            // verifies the final shape.
            execute(connection, sql, true);
        }
        for (String sql : mysql ? CONVERT_MYSQL : CONVERT_OTHER) {
            execute(connection, sql, false);
        }
        for (String sql : ADD_PLATFORM_FKS) {
            execute(connection, sql, false);
        }
    }

    private void execute(Connection connection, String sql, boolean tolerateFailure)
            throws SQLException {
        try (Statement statement = connection.createStatement()) {
            statement.execute(sql);
        } catch (SQLException exception) {
            if (!tolerateFailure) {
                throw new IllegalStateException("Delivery platform migration failed: " + sql,
                        exception);
            }
        }
    }
}
