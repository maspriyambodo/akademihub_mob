import 'failures.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  T get requireData => (this as Success<T>).data;
  Failure get requireFailure => (this as ResultFailure<T>).failure;
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class ResultFailure<T> extends Result<T> {
  final Failure failure;
  const ResultFailure(this.failure);
}

Result<T> success<T>(T data) => Success(data);
Result<T> fail<T>(Failure failure) => ResultFailure(failure);
