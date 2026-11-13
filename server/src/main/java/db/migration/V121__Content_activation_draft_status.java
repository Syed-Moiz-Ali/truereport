package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

/**
 * Allows DRAFT activation state for content that must exist before it can be
 * translated and activated. Creation stays allowed; going ACTIVE is gated by
 * approved translations for every LIVE extended language.
 */
public class V121__Content_activation_draft_status extends BaseJavaMigration {

    private record TableConstraint(String table, String constraint) {
    }

    private static final List<TableConstraint> CONSTRAINTS = List.of(
            new TableConstraint("platform_categories", "ck_content_category_status"),
            new TableConstraint("platform_option_sets", "ck_platform_option_set_status"),
            new TableConstraint("platform_option_values", "ck_platform_option_value_status"),
            new TableConstraint("platform_document_types", "ck_platform_document_type_status")
    );

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        boolean mysql = connection.getMetaData().getDatabaseProductName()
                .toLowerCase().contains("mysql");
        for (TableConstraint item : CONSTRAINTS) {
            drop(connection, item, mysql);
            execute(connection, "ALTER TABLE " + item.table() + " ADD CONSTRAINT "
                    + item.constraint() + " CHECK (status IN ('ACTIVE', 'DRAFT', 'RETIRED'))");
        }
    }

    private void drop(Connection connection, TableConstraint item, boolean mysql) {
        String sql = mysql
                ? "ALTER TABLE " + item.table() + " DROP CHECK " + item.constraint()
                : "ALTER TABLE " + item.table() + " DROP CONSTRAINT " + item.constraint();
        try {
            execute(connection, sql);
        } catch (SQLException ignored) {
            // Constraint may already be absent on a partially migrated schema.
        }
    }

    private void execute(Connection connection, String sql) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            statement.execute(sql);
        }
    }
}
