import UIKit

class ViewController: UITableViewController {
    var allWords = [String]()
    var usedWords = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        let jsonDecoder = JSONDecoder()
        if let usedWordsToLoad = defaults.object(forKey: "usedWords") as? Data {
            do {
                usedWords = try jsonDecoder.decode([String].self, from: usedWordsToLoad)
            } catch {
                print("Failed to load usedWords.")
            }
        }
        if let currentWordToLoad = defaults.object(forKey: "currentWord") as? Data {
            do {
                title = try jsonDecoder.decode(String.self, from: currentWordToLoad)
            } catch {
                print("Failed to load currentWord.")
            }
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promtForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(startGame))
        
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        } 
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
        if usedWords.isEmpty {
            startGame()
        }
    }
    
    @objc func startGame() {
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        saveGameState()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    @objc func promtForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        let submitAction = UIAlertAction(title: "Submit", style: .default) {
            [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowercasedAnswer = answer.lowercased()
        
        if isNotSame(word: lowercasedAnswer) {
            if isLong(word: lowercasedAnswer) {
                if isPossible(word: lowercasedAnswer) {
                    if isOriginal(word: lowercasedAnswer) {
                        if isReal(word: lowercasedAnswer) {
                            usedWords.insert(lowercasedAnswer, at: 0)
                            let indexPath = IndexPath(row: 0, section: 0)
                            saveGameState()
                            tableView.insertRows(at: [indexPath], with: .automatic)
                            
                            return
                        } else {
                            showErrorMessage("This is not a real word.")
                        }
                    } else {
                        showErrorMessage("This word has already been used.")
                    }
                } else {
                    guard let wordFromTitle = title?.lowercased() else { return }
                    showErrorMessage("This word can't be created from \(wordFromTitle).")
                }
            } else {
                showErrorMessage("The word must be atleast 3 letters long.")
            }
        } else {
            showErrorMessage("The word can't be the same as the original.")
        }
    }
    
    func showErrorMessage(_ errorMessage: String) {
        let ac = UIAlertController(title: "Ineligible Word", message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func isPossible (word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }
    
    func isOriginal (word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    func isReal (word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
    
    func isLong (word: String) -> Bool {
        return word.count >= 3
    }
    
    func isNotSame (word: String) -> Bool {
        guard let title = self.title?.lowercased() else { return false }
        return word != title
    }
    
    func saveGameState() {
        if let currentWord = title {
            let defaults = UserDefaults.standard
            let jsonEncoder = JSONEncoder()
            if let savedUsedWords = try? jsonEncoder.encode(usedWords) {
                defaults.set(savedUsedWords, forKey: "usedWords")
            } else {
                print("Failed to save usedWords.")
            }
            if let savedCurrentWord = try? jsonEncoder.encode(currentWord) {
                defaults.set(savedCurrentWord, forKey: "currentWord")
            } else {
                print("Failed to save currentWord.")
            }
        }
    }
}

