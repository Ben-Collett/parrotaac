///This is necessary because ?? gives you null safety but doesn't give you type safety when working with null values
T safeCast<T>(dynamic data, {required T defaultValue}) {
  if (data is T) {
    return data;
  }
  return defaultValue;
}
