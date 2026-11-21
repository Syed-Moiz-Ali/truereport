package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Report documents may now be generated in any language the Platform Admin
 * registry publishes as LIVE, not only {@code en}/{@code ar}. The old
 * {@code ck_platform_report_document_language} constraint blocked every other
 * code, so it is dropped; the service validates the code against the live
 * language registry before inserting a row.
 *
 * <p>Rollback: re-add the constraint only after deleting or converting every
 * non-{@code en}/{@code ar} row, for example
 * {@code ALTER TABLE platform_report_documents ADD CONSTRAINT
 * ck_platform_report_document_language CHECK (language IN ('en', 'ar'))}.</p>
 */
public class V136__Allow_any_document_language extends BaseJavaMigration {

    private static final String CONSTRAINT = "ck_platform_report_document_language";

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        boolean mysql = connection.getMetaData().getDatabaseProductName()
                .toLowerCase().contains("mysql");
        String sql = mysql
                ? "ALTER TABLE platform_report_documents DROP CHECK " + CONSTRAINT
                : "ALTER TABLE platform_report_documents DROP CONSTRAINT " + CONSTRAINT;
        try (Statement statement = connection.createStatement()) {
            statement.execute(sql);
        } catch (SQLException ignored) {
            // Constraint may already be absent on a partially migrated schema.
        }
    }
}
