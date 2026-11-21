package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

/**
 * A platform language code may be up to 16 characters (for example
 * {@code zh-Hant-TW}). The job, delivery and generated-document columns were
 * created as {@code VARCHAR(8)}, which silently excluded longer admin-created
 * LIVE languages. Widen them to match {@code platform_languages.code}.
 *
 * <p>Rollback: shrinking back to {@code VARCHAR(8)} only succeeds after every
 * longer code has been removed or retired and its rows converted. Take a backup
 * first; do not narrow while long codes exist.</p>
 */
public class V137__Widen_language_columns extends BaseJavaMigration {

    private static final List<String> MYSQL = List.of(
            "ALTER TABLE delivery_requests MODIFY language VARCHAR(16) NOT NULL",
            "ALTER TABLE platform_report_documents MODIFY language VARCHAR(16) NOT NULL",
            "ALTER TABLE platform_jobs MODIFY preferred_language VARCHAR(16) NOT NULL DEFAULT 'en'"
    );

    private static final List<String> OTHER = List.of(
            "ALTER TABLE delivery_requests ALTER COLUMN language SET DATA TYPE VARCHAR(16)",
            "ALTER TABLE delivery_requests ALTER COLUMN language SET NOT NULL",
            "ALTER TABLE platform_report_documents ALTER COLUMN language SET DATA TYPE VARCHAR(16)",
            "ALTER TABLE platform_report_documents ALTER COLUMN language SET NOT NULL",
            "ALTER TABLE platform_jobs ALTER COLUMN preferred_language SET DATA TYPE VARCHAR(16)",
            "ALTER TABLE platform_jobs ALTER COLUMN preferred_language SET DEFAULT 'en'",
            "ALTER TABLE platform_jobs ALTER COLUMN preferred_language SET NOT NULL"
    );

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        boolean mysql = connection.getMetaData().getDatabaseProductName()
                .toLowerCase().contains("mysql");
        for (String sql : mysql ? MYSQL : OTHER) {
            try (Statement statement = connection.createStatement()) {
                statement.execute(sql);
            } catch (SQLException exception) {
                throw new IllegalStateException("Language column migration failed: " + sql,
                        exception);
            }
        }
    }
}
