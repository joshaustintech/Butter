import Testing
@testable import Butter

struct RecipeTextParserTests {
    @Test func titleIsFirstNonEmptyLine() {
        let recipe = RecipeTextParser.parse(text: "\n   \nLemon Cake\nIngredients\n2 cups flour")
        #expect(recipe.title == "Lemon Cake")
    }

    @Test func emptyInputYieldsUntitledEmptyRecipe() {
        let recipe = RecipeTextParser.parse(text: "")
        #expect(recipe == ImportedRecipe(title: "Untitled Recipe", ingredients: [], steps: [], sourceURL: nil, imageURL: nil))
    }

    @Test func whitespaceOnlyInputDoesNotCrash() {
        let recipe = RecipeTextParser.parse(text: " \n\t\n  ")
        #expect(recipe.title == "Untitled Recipe")
        #expect(recipe.ingredients.isEmpty)
        #expect(recipe.steps.isEmpty)
    }

    @Test func sourceAndImageURLsAreAlwaysNil() {
        let recipe = RecipeTextParser.parse(text: "Soup\nIngredients\nstock\nDirections\nBoil")
        #expect(recipe.sourceURL == nil)
        #expect(recipe.imageURL == nil)
    }

    @Test func headingsWithoutTitleFallBackToUntitledRecipe() {
        let recipe = RecipeTextParser.parse(text: "Ingredients\nflour\nDirections\nMix")
        #expect(recipe.title == "Untitled Recipe")
        #expect(recipe.ingredients == ["flour"])
        #expect(recipe.steps == ["Mix"])
    }

    @Test(arguments: ["Ingredients", "INGREDIENTS:", "ingredients :"])
    func ingredientsHeadingIsCaseInsensitiveWithOptionalColon(heading: String) {
        let recipe = RecipeTextParser.parse(text: "Pancakes\n\(heading)\nflour\nmilk\nDirections\nMix")
        #expect(recipe.ingredients == ["flour", "milk"])
    }

    @Test(arguments: ["Directions", "Method", "instructions:", "STEPS:"])
    func methodHeadingsAreCaseInsensitiveWithOptionalColon(heading: String) {
        let recipe = RecipeTextParser.parse(text: "Pancakes\nIngredients\nflour\n\(heading)\nMix the batter\nCook it")
        #expect(recipe.steps == ["Mix the batter", "Cook it"])
    }

    @Test func ingredientBulletsAreStripped() {
        let recipe = RecipeTextParser.parse(text: "Soup\nIngredients\n- carrots\n• onions\n* celery\nDirections\nChop")
        #expect(recipe.ingredients == ["carrots", "onions", "celery"])
    }

    @Test func stepNumberingIsStripped() {
        let recipe = RecipeTextParser.parse(text: "Soup\nDirections\n1. Chop the onions\n2) Fry them\nStep 3: Simmer")
        #expect(recipe.steps == ["Chop the onions", "Fry them", "Simmer"])
    }

    @Test func wrappedLinesMergeIntoPreviousNumberedStep() {
        let recipe = RecipeTextParser.parse(text: "Soup\nDirections\n1. Simmer the stock\nfor twenty minutes\n2. Serve hot")
        #expect(recipe.steps == ["Simmer the stock for twenty minutes", "Serve hot"])
    }

    @Test func parentheticalWrappedLineMergesIntoPreviousStep() {
        let recipe = RecipeTextParser.parse(text: "Soup\nDirections\n1. Fry the onions\n(about ten minutes)")
        #expect(recipe.steps == ["Fry the onions (about ten minutes)"])
    }

    @Test func capitalisedLineAfterNumberedListStartsNewStep() {
        let recipe = RecipeTextParser.parse(text: "Soup\nDirections\n1. Chop the onions\nStir them well\n2. Fry")
        #expect(recipe.steps == ["Chop the onions", "Stir them well", "Fry"])
    }

    @Test func lineStartingWithNumberAfterNumberedListStartsNewStep() {
        let recipe = RecipeTextParser.parse(text: "Soup\nDirections\n1. Bake\n20 minutes later, check")
        #expect(recipe.steps == ["Bake", "20 minutes later, check"])
    }

    @Test func unlabeledQuantityLinesBecomeIngredients() {
        let recipe = RecipeTextParser.parse(text: "Pancakes\n2 cups flour\n½ tsp salt\n1 tbsp butter\ncup of milk")
        #expect(recipe.ingredients == ["2 cups flour", "½ tsp salt", "1 tbsp butter", "cup of milk"])
        #expect(recipe.steps.isEmpty)
    }

    @Test func unlabeledSentencesBecomeSteps() {
        let recipe = RecipeTextParser.parse(text: "Pancakes\n2 cups flour\nWhisk the flour and milk together until smooth.\nFry on a hot pan for two minutes.")
        #expect(recipe.ingredients == ["2 cups flour"])
        #expect(recipe.steps == ["Whisk the flour and milk together until smooth.", "Fry on a hot pan for two minutes."])
    }

    @Test func unlabeledNumberedLinesAreStepsNotIngredients() {
        let recipe = RecipeTextParser.parse(text: "Pancakes\n1. Preheat the pan\n2. Pour the batter")
        #expect(recipe.steps == ["Preheat the pan", "Pour the batter"])
        #expect(recipe.ingredients.isEmpty)
    }

    @Test func unlabeledWrappedLineMergesIntoPreviousStep() {
        let recipe = RecipeTextParser.parse(text: "Pancakes\n1. Whisk well\nuntil smooth")
        #expect(recipe.steps == ["Whisk well until smooth"])
    }

    @Test func unlabeledShortNonQuantityLinesAreDropped() {
        let recipe = RecipeTextParser.parse(text: "Pancakes\nServes 4\n2 cups flour")
        #expect(recipe.ingredients == ["2 cups flour"])
        #expect(recipe.steps.isEmpty)
    }

    @Test func windowsLineEndingsAreHandled() {
        let recipe = RecipeTextParser.parse(text: "Pancakes\r\nIngredients\r\nflour\r\nDirections\r\nMix")
        #expect(recipe == ImportedRecipe(title: "Pancakes", ingredients: ["flour"], steps: ["Mix"], sourceURL: nil, imageURL: nil))
    }
}
