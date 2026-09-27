param(
    [string]$SourceMarkdown = "E:\Melanoma skin cancer\docs\TIDAC_2026_BLIND_REVIEW_PAPER.md",
    [string]$TemplatePath = "C:\Users\prave\Desktop\Tidac\TIDAC-2026 -Template.docx",
    [string]$OutputDocx = "C:\Users\prave\Desktop\Tidac\TIDAC_2026_Blind_Review_Paper.docx",
    [string]$OutputPdf = "C:\Users\prave\Desktop\Tidac\TIDAC_2026_Blind_Review_Paper.pdf"
)

$ErrorActionPreference = "Stop"

function Get-MarkdownSections {
    param([string]$Path)

    $text = Get-Content -LiteralPath $Path -Raw
    $titleMatch = [regex]::Match($text, '(?m)^#\s+(.+)$')
    if (-not $titleMatch.Success) {
        throw "Could not find the paper title in $Path"
    }

    $sections = [ordered]@{}
    $sectionMatches = [regex]::Matches($text, '(?ms)^##\s+(.+?)\r?\n(.*?)(?=^##\s+|\z)')
    foreach ($match in $sectionMatches) {
        $name = $match.Groups[1].Value.Trim()
        $body = $match.Groups[2].Value.Trim()
        $sections[$name] = $body
    }

    return @{
        Title = $titleMatch.Groups[1].Value.Trim()
        Sections = $sections
    }
}

function Split-Paragraphs {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    return ($Text -split '\r?\n\s*\r?\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Add-StyledParagraph {
    param(
        $Selection,
        [string]$StyleName,
        [string]$Text
    )

    $Selection.Style = $StyleName
    $Selection.TypeText($Text)
    $Selection.TypeParagraph()
}

$paper = Get-MarkdownSections -Path $SourceMarkdown

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0

    $doc = $word.Documents.Open($TemplatePath)

    $doc.Paragraphs.Item(1).Range.Text = $paper.Title + "`r"

    $abstractStart = $doc.Paragraphs.Item(10).Range.Start
    $authorBlockStart = $doc.Paragraphs.Item(2).Range.Start
    $doc.Range($authorBlockStart, $abstractStart).Delete() | Out-Null

    $emdash = [char]8212
    $doc.Paragraphs.Item(2).Range.Text = "Abstract$emdash" + $paper.Sections["Abstract"] + "`r"
    $doc.Paragraphs.Item(3).Range.Text = "Keywords$emdash" + $paper.Sections["Keywords"] + "`r"

    $bodyStart = $doc.Paragraphs.Item(4).Range.Start
    $doc.Range($bodyStart, $doc.Content.End - 1).Delete() | Out-Null

    $selection = $word.Selection
    $selection.SetRange($doc.Content.End - 1, $doc.Content.End - 1)

    Add-StyledParagraph -Selection $selection -StyleName "Heading 1" -Text "Introduction"
    foreach ($paragraph in (Split-Paragraphs $paper.Sections["Introduction"])) {
        Add-StyledParagraph -Selection $selection -StyleName "Body Text" -Text $paragraph
    }

    Add-StyledParagraph -Selection $selection -StyleName "Heading 1" -Text "Methodology"
    foreach ($paragraph in (Split-Paragraphs $paper.Sections["Methodology"])) {
        Add-StyledParagraph -Selection $selection -StyleName "Body Text" -Text $paragraph
    }

    Add-StyledParagraph -Selection $selection -StyleName "Heading 1" -Text "Results and Discussion"
    foreach ($paragraph in (Split-Paragraphs $paper.Sections["Results and Discussion"])) {
        Add-StyledParagraph -Selection $selection -StyleName "Body Text" -Text $paragraph
    }

    Add-StyledParagraph -Selection $selection -StyleName "Heading 1" -Text "Conclusion"
    foreach ($paragraph in (Split-Paragraphs $paper.Sections["Conclusion"])) {
        Add-StyledParagraph -Selection $selection -StyleName "Body Text" -Text $paragraph
    }

    Add-StyledParagraph -Selection $selection -StyleName "Heading 5" -Text "References"
    foreach ($reference in ($paper.Sections["References"] -split '\r?\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        Add-StyledParagraph -Selection $selection -StyleName "references" -Text $reference
    }

    $doc.SaveAs([ref]$OutputDocx)
    $doc.ExportAsFixedFormat($OutputPdf, 17)

    "Saved DOCX: $OutputDocx"
    "Saved PDF: $OutputPdf"
    "Page count: $($doc.ComputeStatistics(2))"
}
finally {
    if ($doc) {
        $doc.Close([ref]0) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
    }
    if ($word) {
        $word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    }
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
}
