/// Status of local persistence storage after application bootstrap.
class LocalStorageStatus {
  final bool isPersistent;
  final String storageNamespace;

  const LocalStorageStatus({
    required this.isPersistent,
    required this.storageNamespace,
  });

  @override
  String toString() =>
      'LocalStorageStatus(isPersistent: $isPersistent, storageNamespace: $storageNamespace)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalStorageStatus &&
          runtimeType == other.runtimeType &&
          isPersistent == other.isPersistent &&
          storageNamespace == other.storageNamespace;

  @override
  int get hashCode => Object.hash(isPersistent, storageNamespace);
}
