package com.truereport.uimessages.api;

public interface UiMessagePublishGuard {

    void requirePublishable(String languageCode, String uiMessagesPath, String defaultLanguagePath);
}
