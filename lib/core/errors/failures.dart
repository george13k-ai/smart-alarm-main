abstract class Failure {
  final String message;
  const Failure(this.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class HealthConnectFailure extends Failure {
  const HealthConnectFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class NotificationFailure extends Failure {
  const NotificationFailure(super.message);
}
