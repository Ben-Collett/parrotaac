class AttributionData {
  final List<AttributionProperty> properties;
  const AttributionData(this.properties);
}

class AttributionProperty {
  final String label;
  final String? value;
  final String? url;

  const AttributionProperty({
    required this.label,
    required this.value,
    this.url,
  });
}
