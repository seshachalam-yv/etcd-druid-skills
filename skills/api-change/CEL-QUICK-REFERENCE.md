# CEL Quick Reference

```cel
# Optional field guard
has(self.fieldName)

# Presence immutability
has(oldSelf.field) == has(self.field)

# Value immutability
self == oldSelf

# Duration comparison
duration(self.period1).getSeconds() < duration(self.period2).getSeconds()

# List: all elements satisfy predicate
self.myList.all(item, item.field > 0)

# Nested list iteration
self.myList.all(m, m.urls.all(u, u.startsWith('https://')))

# String prefix
self.name.startsWith(self.metadata.name + '-')

# Regex match
self.name.matches('^[a-z0-9]([-a-z0-9]*[a-z0-9])?-[0-9]+$')

# Extract integer from suffix after last dash
int(self.name.substring(self.name.lastIndexOf('-') + 1))

# Combine optional guard with rule (cross-field pattern)
!has(self.spec.etcd.myField) || self.spec.etcd.myField.all(m, <rule>)
```
