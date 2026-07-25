# Basic Usage

```dart
ExampleConnector.instance.ListTenants().execute();
ExampleConnector.instance.ListUsers().execute();
ExampleConnector.instance.ListBusinesses(listBusinessesVariables).execute();
ExampleConnector.instance.getUserByEmail(getUserByEmailVariables).execute();
ExampleConnector.instance.getBusinessById(getBusinessByIdVariables).execute();
ExampleConnector.instance.getBusinessByCode(getBusinessByCodeVariables).execute();
ExampleConnector.instance.verifyUserLogin(verifyUserLoginVariables).execute();
ExampleConnector.instance.listProductsByBusiness(listProductsByBusinessVariables).execute();
ExampleConnector.instance.listCustomersByBusiness(listCustomersByBusinessVariables).execute();
ExampleConnector.instance.listUsersByBusiness(listUsersByBusinessVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await ExampleConnector.instance.UpdateTask({ ... })
.title(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

