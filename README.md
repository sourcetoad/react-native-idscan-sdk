# react-native-idscan-sdk

React Native ID Scanner wrapper for idscan sdk

## Installation

```sh
npm install react-native-idscan-sdk
```

## Usage

```js
import { scan } from 'react-native-idscan-sdk';

// ...

const result = await scan(
  'CAMERA_KEY_HERE',
  'PARSER_KEY_HERE',
  (error, scannedData) => console.log(error, scannedData)
);
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
