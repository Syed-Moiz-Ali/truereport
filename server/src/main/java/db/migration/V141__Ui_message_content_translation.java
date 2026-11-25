package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

/**
 * Static interface strings join the content translation pipeline.
 *
 * <p>UI-message entity ids are {@code namespace:key} (for example
 * {@code platform_admin:page.title}), so the 36-character uuid columns must be
 * widened. The new {@code UI_MESSAGE}/{@code value} field is registered as
 * non-safety-critical.</p>
 */
public class V141__Ui_message_content_translation extends BaseJavaMigration {

    private static final List<String> TABLES =
            List.of("content_translation", "content_translation_job");

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        boolean mysql = connection.getMetaData().getDatabaseProductName()
                .toLowerCase().contains("mysql");
        for (String table : TABLES) {
            String sql = mysql
                    ? "ALTER TABLE " + table + " MODIFY entity_id VARCHAR(320) NOT NULL"
                    : "ALTER TABLE " + table + " ALTER COLUMN entity_id SET DATA TYPE VARCHAR(320)";
            // The columns may already be wide on a partially migrated schema.
            execute(connection, sql, true);
        }
        execute(connection, """
                INSERT INTO translatable_field
                    (entity_type, field_name, max_length, protect_patterns,
                     safety_critical, enabled)
                SELECT 'UI_MESSAGE', 'value', 4000, NULL, FALSE, TRUE
                WHERE NOT EXISTS (
                    SELECT 1 FROM translatable_field
                    WHERE entity_type = 'UI_MESSAGE' AND field_name = 'value'
                )
                """, false);
    }

    private void execute(Connection connection, String sql, boolean tolerateFailure)
            throws SQLException {
        try (Statement statement = connection.createStatement()) {
            statement.execute(sql);
        } catch (SQLException exception) {
            if (!tolerateFailure) {
                throw new IllegalStateException("UI message translation migration failed: " + sql,
                        exception);
            }
        }
    }
}
