package com.truereport;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import org.springframework.modulith.core.ApplicationModules;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

@AnalyzeClasses(packages = "com.truereport")
class ArchitectureTest {

    @ArchTest
    static final ArchRule controllersDoNotAccessRepositoriesDirectly =
            noClasses().that().haveSimpleNameEndingWith("Controller")
                    .should().dependOnClassesThat().haveSimpleNameEndingWith("Repository");

    @ArchTest
    static void springModulithBoundariesAreValid(JavaClasses classes) {
        ApplicationModules.of(TrueReportApplication.class).verify();
    }
}
