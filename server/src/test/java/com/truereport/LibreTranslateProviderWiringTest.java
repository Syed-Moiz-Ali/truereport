package com.truereport;

import com.truereport.shared.i18n.TranslationProvider;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Guards the Spring wiring of the real provider: the class has a test-only
 * constructor, so the bean must still be creatable from properties.
 */
@SpringBootTest
@ActiveProfiles("test")
@Import(TestSecurityConfig.class)
@TestPropertySource(properties = {
        "truereport.i18n.translation.provider=libretranslate",
        "truereport.i18n.translation.libretranslate.url=http://127.0.0.1:1"
})
class LibreTranslateProviderWiringTest {

    @Autowired
    TranslationProvider provider;

    @Test
    void providerBeanLoadsFromProperties() {
        assertThat(provider.id()).isEqualTo("libretranslate");
    }
}
