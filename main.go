// MyKryonApp/main.go
package main

import (
	"flag"
	"log"
	"os"

	// Import necessary packages from your Kryon library
	"github.com/waozixyz/kryon/impl/go/krb"
	"github.com/waozixyz/kryon/impl/go/render"
	"github.com/waozixyz/kryon/impl/go/render/raylib")

// --- Application-Specific Globals (if needed) ---
var (
	appRenderer render.Renderer // Use the interface
	krbDocument *krb.Document
	allElements []*render.RenderElement
)

// --- Application-Specific Event Handlers ---
func handleTab1() {
	log.Println("Tab 1 Clicked!")
	// Add logic to change content, etc.
}

func handleTab2() {
	log.Println("Tab 2 Clicked!")
	// Add logic
}

// --- (Optional) Application-Specific Custom Component Handlers ---
/*
// Example: If you wanted to override TabBar behavior
type MyCustomTabBarHandler struct {
    raylib.TabBarHandler // Embed default handler (composition)
}

func (h *MyCustomTabBarHandler) HandleLayoutAdjustment(el *render.RenderElement, doc *krb.Document) error {
    log.Println("MY Custom TabBar Layout!")
    // Call default logic if needed: h.TabBarHandler.HandleLayoutAdjustment(el, doc)
    // Add custom adjustments
    return nil
}
*/

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// --- CLI Args for this App ---
	krbFile := flag.String("krb", "ui/app.krb", "Path to the compiled KRB file") // Default relative path
	flag.Parse()

	log.Printf("Loading KRB file: %s", *krbFile)

	// --- Load KRB ---
	file, err := os.Open(*krbFile)
	if err != nil { log.Fatalf("ERROR opening KRB file '%s': %v", *krbFile, err) }
	defer file.Close()

	doc, err := krb.ReadDocument(file)
	if err != nil { log.Fatalf("ERROR parsing KRB file '%s': %v", *krbFile, err) }
	krbDocument = doc // Store for potential lookups by handlers
	log.Printf("Parsed KRB OK - Elements: %d", doc.Header.ElementCount)
	if doc.Header.ElementCount == 0 { return }

	// --- Initialize Renderer ---
	// Create an instance of the desired renderer implementation.
	renderer := raylib.NewRaylibRenderer()
	appRenderer = renderer // Store globally (simple approach)

	// --- Register Event Handlers (Application Specific) ---
	// Map names used in your app's KRB `onClick` etc. to your Go functions.
	log.Println("Registering event handlers...")
	renderer.RegisterEventHandler("handleTab1", handleTab1)
	renderer.RegisterEventHandler("handleTab2", handleTab2)
	// Add other handlers...

	// --- Register Custom Component Handlers ---
	// Decide whether to use library defaults or your app's custom handlers.
	log.Println("Registering custom component handlers...")
	// Use the *default* TabBarHandler from the library
	err = renderer.RegisterCustomComponent("TabBar", &raylib.TabBarHandler{})
	if err != nil { log.Printf("WARN: Failed to register TabBar handler: %v", err) }

	// Example: Use a custom handler IF you defined one above
	// err = renderer.RegisterCustomComponent("TabBar", &MyCustomTabBarHandler{})
	// if err != nil { log.Printf("WARN: Failed to register custom TabBar handler: %v", err) }

	// Register handlers for other components used (e.g., MarkdownView if used & handler available)
	// err = renderer.RegisterCustomComponent("MarkdownView", &raylib.MarkdownViewHandler{})
	// ...

	// --- Prepare Tree & Initialize Window ---
	log.Println("Preparing render tree...")
	roots, windowConfig, err := renderer.PrepareTree(doc, *krbFile) // Pass krbFile path for resource loading context
	if err != nil { log.Fatalf("ERROR preparing render tree: %v", err) }
	allElements = renderer.GetRenderTree() // Store for handlers

	log.Println("Initializing window...")
	err = renderer.Init(windowConfig)
	if err != nil { renderer.Cleanup(); log.Fatalf("ERROR initializing renderer: %v", err) }
	defer renderer.Cleanup()

	// --- Load Textures ---
	log.Println("Loading textures...")
	err = renderer.LoadAllTextures() // Call after Init
	if err != nil { log.Printf("WARNING loading textures: %v", err) }

	// --- Main Loop ---
	log.Println("Starting main loop...")
	for !renderer.ShouldClose() {
		renderer.PollEvents()     // Handle input
		// Add app-specific update logic here if needed
		renderer.BeginFrame()     // Clear background
		renderer.RenderFrame(roots) // Layout & Draw UI
		renderer.EndFrame()       // Swap buffers
	}

	log.Println("Exiting application.")
}