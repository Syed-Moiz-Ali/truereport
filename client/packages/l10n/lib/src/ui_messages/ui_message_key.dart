final class UiMessageKey {
  const UiMessageKey(this.namespace, this.key);

  const UiMessageKey.common(this.key) : namespace = 'common';

  const UiMessageKey.platformAdmin(this.key) : namespace = 'platform_admin';

  const UiMessageKey.workshopAdmin(this.key) : namespace = 'workshop_admin';

  const UiMessageKey.technician(this.key) : namespace = 'technician';

  final String namespace;

  final String key;

  String get qualified => '$namespace.$key';

  @override
  bool operator ==(Object other) =>
      other is UiMessageKey && other.namespace == namespace && other.key == key;

  @override
  int get hashCode => Object.hash(namespace, key);

  @override
  String toString() => qualified;
}
