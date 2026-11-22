import Foundation
import Testing
@testable import Butter

struct RecipeJSONLDParserTests {
    private func page(_ json: String) -> String {
        "<html><head><script type=\"application/ld+json\">\(json)</script></head><body></body></html>"
    }

    private let pageURL = URL(string: "https://example.com/recipes/pancakes")

    @Test func topLevelObject() throws {
        let html = page(#"{"@context":"https://schema.org","@type":"Recipe","name":"Pancakes","recipeIngredient":["1 cup flour","2 eggs"],"recipeInstructions":"Mix.\nCook."}"#)
        let recipe = try #require(RecipeJSONLDParser.parse(html: html, pageURL: pageURL))
        #expect(recipe.title == "Pancakes")
        #expect(recipe.ingredients == ["1 cup flour", "2 eggs"])
        #expect(recipe.steps == ["Mix.", "Cook."])
        #expect(recipe.sourceURL == pageURL)
    }

    @Test func topLevelArray() throws {
        let html = page(#"[{"@type":"WebSite","name":"Site"},{"@type":"Recipe","name":"Toast"}]"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.title == "Toast")
    }

    @Test func graph() throws {
        let html = page(#"{"@context":"https://schema.org","@graph":[{"@type":"Organization","name":"Org"},{"@type":"Recipe","name":"Soup"}]}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.title == "Soup")
    }

    @Test func typeAsArray() throws {
        let html = page(#"{"@type":["Article","Recipe"],"name":"Stew"}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.title == "Stew")
    }

    @Test func instructionsAsArrayOfStrings() throws {
        let html = page(#"{"@type":"Recipe","name":"A","recipeInstructions":["One","Two"]}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.steps == ["One", "Two"])
    }

    @Test func instructionsAsHowToSteps() throws {
        let html = page(#"{"@type":"Recipe","name":"A","recipeInstructions":[{"@type":"HowToStep","text":"One"},{"@type":"HowToStep","text":"Two"}]}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.steps == ["One", "Two"])
    }

    @Test func instructionsAsHowToSections() throws {
        let html = page(#"{"@type":"Recipe","name":"A","recipeInstructions":[{"@type":"HowToSection","name":"Dough","itemListElement":[{"@type":"HowToStep","text":"Knead"}]},{"@type":"HowToSection","name":"Bake","itemListElement":[{"@type":"HowToStep","text":"Bake"},{"@type":"HowToStep","text":"Cool"}]}]}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.steps == ["Knead", "Bake", "Cool"])
    }

    @Test func imageAsString() throws {
        let html = page(#"{"@type":"Recipe","name":"A","image":"https://example.com/a.jpg"}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.imageURL == URL(string: "https://example.com/a.jpg"))
    }

    @Test func imageAsArray() throws {
        let html = page(#"{"@type":"Recipe","name":"A","image":["https://example.com/1.jpg","https://example.com/2.jpg"]}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.imageURL == URL(string: "https://example.com/1.jpg"))
    }

    @Test func imageAsImageObject() throws {
        let html = page(#"{"@type":"Recipe","name":"A","image":{"@type":"ImageObject","url":"https://example.com/o.jpg"}}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.imageURL == URL(string: "https://example.com/o.jpg"))
    }

    @Test func relativeImageResolvesAgainstPage() throws {
        let html = page(#"{"@type":"Recipe","name":"A","image":"/img/a.jpg"}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: pageURL)?.imageURL == URL(string: "https://example.com/img/a.jpg"))
    }

    @Test func decodesEntitiesAndStripsTags() throws {
        let html = page(#"{"@type":"Recipe","name":"Mac &amp; Cheese &#39;n&#x27; More","recipeIngredient":["<b>2</b> cups  milk"],"recipeInstructions":"<p>Boil &lt;water&gt;.</p><p>Drain.</p>"}"#)
        let recipe = try #require(RecipeJSONLDParser.parse(html: html, pageURL: nil))
        #expect(recipe.title == "Mac & Cheese 'n' More")
        #expect(recipe.ingredients == ["2 cups milk"])
        #expect(recipe.steps == ["Boil <water>.", "Drain."])
    }

    @Test func trimsWhitespace() throws {
        let html = page(#"{"@type":"Recipe","name":"  Pie \n ","recipeIngredient":["  apples  "],"recipeInstructions":["  Bake.  "]}"#)
        let recipe = try #require(RecipeJSONLDParser.parse(html: html, pageURL: nil))
        #expect(recipe.title == "Pie")
        #expect(recipe.ingredients == ["apples"])
        #expect(recipe.steps == ["Bake."])
    }

    @Test func skipsInvalidBlockAndUsesLaterOne() throws {
        let html = "<script type=\"application/ld+json\">{not json</script>" + page(#"{"@type":"Recipe","name":"Ok"}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil)?.title == "Ok")
    }

    @Test func nilWhenNoRecipe() {
        let html = page(#"{"@type":"Article","name":"News"}"#)
        #expect(RecipeJSONLDParser.parse(html: html, pageURL: nil) == nil)
        #expect(RecipeJSONLDParser.parse(html: "<html></html>", pageURL: nil) == nil)
    }

    @Test func nilWhenNoTitle() {
        #expect(RecipeJSONLDParser.parse(html: page(#"{"@type":"Recipe","recipeIngredient":["x"]}"#), pageURL: nil) == nil)
        #expect(RecipeJSONLDParser.parse(html: page(#"{"@type":"Recipe","name":"   "}"#), pageURL: nil) == nil)
    }
}
