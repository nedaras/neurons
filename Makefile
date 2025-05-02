run:
	@templ generate
	@npx @tailwindcss/cli -i src/styles/tailwind.css -o public/styles.css
	@go run main.go
