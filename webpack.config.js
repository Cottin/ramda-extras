import path from 'path'
import {fileURLToPath} from 'url'
import glob from 'glob'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const testEntries = glob.sync("./src/**/test__*.coffee").reduce((acc, val) => {
			const filenameRegex = /test__([\w\d_-]*)\.coffee$/i
			acc[val.match(filenameRegex)[1]] = val
			return acc
		}, {})

const config = {
	entry: testEntries,
	mode: 'development',

	devtool: 'inline-cheap-module-source-map',
	// devtool: 'cheap-module-source-map',

	output: {
		filename: '[name].test.js',
		path: path.resolve(__dirname, 'temp'),
		clean: true,
	},
	module: {
		rules: [
			{
				include: [
					path.resolve(__dirname),
					path.resolve(__dirname, '../comon'),
				],
				exclude: /node_modules|packages/,
				test: /\.coffee$/,
				use: [
					{loader: 'coffee-loader'},
					{loader: path.resolve(__dirname, '../hack/loaders/keywordCoffeeLoader.js')},
				]
			},
		],
	},
	target: 'node',
	resolve: {
		extensions: ['.js', '.coffee'],
		alias: {
			comon: path.resolve(__dirname, '../comon')
		}
	},
}

export default config
