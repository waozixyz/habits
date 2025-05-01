// MyKryonApp/main.go
package main

import (
	"flag"
	"log"
	"os"

	"github.com/waozixyz/kryon/impl/go/krb"
	"github.com/waozixyz/kryon/impl/go/render"
	"github.com/waozixyz/kryon/impl/go/render/raylib"
)

// --- Application-Specific Globals ---
var (
	appRenderer           render.Renderer
	krbDocument           *krb.Document
	allElements           []*render.RenderElement
	tabButtonStyleBaseIdx   uint8 = 0 // String table index for "tab_item_style_base"
	tabButtonStyleActiveIdx uint8 = 0 // String table index for "tab_item_style_active_base"
)

// --- findElementByID (Helper Function - Corrected Header.ID usage) ---
func findElementByID(idName string) *render.RenderElement {
	if len(allElements) == 0 || krbDocument == nil {
		// log.Printf("WARN findElementByID: State not ready...") // Optional log
		return nil
	}
	targetIDIndex := uint8(0)
	found := false
	for idx, str := range krbDocument.Strings {
		if str == idName {
			targetIDIndex = uint8(idx)
			found = true
			break
		}
	}
	if !found {
		// log.Printf("WARN findElementByID: Element ID '%s' not found in string table.", idName) // Optional log
		return nil
	}
	for _, el := range allElements {
		if el != nil && el.Header.ID == targetIDIndex { // Use Header.ID
			return el
		}
	}
	// log.Printf("WARN findElementByID: Element with ID '%s' not found in render tree.", idName) // Optional log
	return nil
}

// --- setActivePage (Application Logic - Hides/shows page containers) ---
func setActivePage(visiblePageID string) {
	log.Printf("ACTION: Setting active page to '%s'", visiblePageID)
	pageIDs := []string{"page_tab1", "page_tab2"} // Match IDs in app.kry

	foundTargetPage := false
	for _, pageID := range pageIDs {
		pageElement := findElementByID(pageID)
		if pageElement != nil {
			shouldBeVisible := (pageID == visiblePageID)
			if shouldBeVisible != pageElement.IsVisible {
				pageElement.IsVisible = shouldBeVisible
				log.Printf("      Elem %d ('%s') visibility set to %t", pageElement.OriginalIndex, pageID, shouldBeVisible)
			}
			if shouldBeVisible {
				foundTargetPage = true
			}
		} else {
			log.Printf("WARN setActivePage: Could not find page element with ID '%s'", pageID)
		}
	}
	if !foundTargetPage && visiblePageID != "" {
		log.Printf("WARN setActivePage: Requested page '%s' not found or could not be made visible.", visiblePageID)
	}
}


// Sets the IsActive flag on tab buttons based on which one should be active.
func updateTabStyles(activeButtonID string) {
	log.Printf("ACTION: Setting active tab button style for '%s'", activeButtonID)
	// List of tab button IDs defined in app.kry
	tabButtonIDs := []string{"button_tab1", "button_tab2"} // Add more if needed

	for _, buttonID := range tabButtonIDs {
		buttonElement := findElementByID(buttonID)
		if buttonElement != nil {
			shouldBeActive := (buttonID == activeButtonID)
			if shouldBeActive != buttonElement.IsActive {
				buttonElement.IsActive = shouldBeActive
				log.Printf("      Elem %d ('%s') IsActive set to %t", buttonElement.OriginalIndex, buttonID, shouldBeActive)
			}
			// Assign the style name indices needed for drawing lookup
			buttonElement.InactiveStyleNameIndex = tabButtonStyleBaseIdx
			buttonElement.ActiveStyleNameIndex = tabButtonStyleActiveIdx
		} else {
			log.Printf("WARN updateTabStyles: Could not find tab button element with ID '%s'", buttonID)
		}
	}
}


// --- Event Handler Functions (Called by KRB events) ---
func handleTab1() {
	log.Println("Event: handleTab1 triggered")
	setActivePage("page_tab1")    // Show page 1
	updateTabStyles("button_tab1") // <<< ADD THIS LINE: Set button_tab1 as active
}

func handleTab2() {
	log.Println("Event: handleTab2 triggered")
	setActivePage("page_tab2")    // Show page 2
	updateTabStyles("button_tab2") // <<< ADD THIS LINE: Set button_tab2 as active
}


// --- Main Application Entry Point ---
func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	krbFile := flag.String("krb", "ui/app.krb", "Path to the compiled KRB file")
	flag.Parse()

	log.Printf("Loading KRB file: %s", *krbFile)

	file, err := os.Open(*krbFile)
	if err != nil { log.Fatalf("ERROR opening KRB file '%s': %v", *krbFile, err) }
	defer file.Close()

	doc, err := krb.ReadDocument(file)
	if err != nil { log.Fatalf("ERROR parsing KRB file '%s': %v", *krbFile, err) }
	krbDocument = doc
	log.Printf("Parsed KRB OK - Elements: %d", doc.Header.ElementCount)
	if doc.Header.ElementCount == 0 { return }

	// --- Find Style Name Indices ---
	// We need the string table indices for the style *names* to look them up later.
	foundBase := false
	foundActive := false
	for idx, name := range doc.Strings {
		if name == "tab_item_style_base" {
			tabButtonStyleBaseIdx = uint8(idx)
			foundBase = true
		} else if name == "tab_item_style_active_base" {
			tabButtonStyleActiveIdx = uint8(idx)
			foundActive = true
		}
		if foundBase && foundActive {
			break
		}
	}
	if !foundBase || !foundActive {
		log.Printf("WARN: Could not find one or both required tab button style name indices ('tab_item_style_base', 'tab_item_style_active_base') in string table. Style switching may fail.")
		// Handle this error more robustly if needed (e.g., exit)
	} else {
		log.Printf("Found tab style name indices: Base=%d, Active=%d", tabButtonStyleBaseIdx, tabButtonStyleActiveIdx)
	}

	// --- Initialize Renderer ---
	renderer := raylib.NewRaylibRenderer()
	appRenderer = renderer

	// --- Register Event Handlers ---
	log.Println("Registering event handlers...")
	renderer.RegisterEventHandler("handleTab1", handleTab1)
	renderer.RegisterEventHandler("handleTab2", handleTab2)

	// --- Register Custom Component Handlers ---
	log.Println("Registering custom component handlers...")
	err = renderer.RegisterCustomComponent("TabBar", &raylib.TabBarHandler{})
	if err != nil { log.Printf("WARN: Failed to register TabBar handler: %v", err) }

	// --- Prepare Tree & Initialize Window ---
	log.Println("Preparing render tree...")
	roots, windowConfig, err := renderer.PrepareTree(doc, *krbFile)
	if err != nil { log.Fatalf("ERROR preparing render tree: %v", err) }
	allElements = renderer.GetRenderTree() // Store flat list *after* PrepareTree

	log.Println("Initializing window...")
	err = renderer.Init(windowConfig)
	if err != nil { renderer.Cleanup(); log.Fatalf("ERROR initializing renderer: %v", err) }
	defer renderer.Cleanup()

	// --- Load Textures ---
	log.Println("Loading textures...")
	err = renderer.LoadAllTextures()
	if err != nil { log.Printf("WARNING loading textures: %v", err) }

	// --- Initial UI State Setup ---
	setActivePage("page_tab1")   // Set initial visible page
	updateTabStyles("button_tab1") // Set initial active tab button style

	// --- Main Loop ---
	log.Println("Starting main loop...")
	for !renderer.ShouldClose() {
		renderer.PollEvents()       // Handles input, triggers handleTab1/handleTab2 -> updateTabStyles
		renderer.BeginFrame()
		renderer.RenderFrame(roots) // Drawing logic will now use IsActive flag
		renderer.EndFrame()
	}

	log.Println("Exiting application.")
}
