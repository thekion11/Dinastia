#include "draftdata.hpp"

#include <algorithm>
#include <cstdlib>
#include "misc/rng.hpp"

static const char* kFirstNames[] = {"James", "Lucas", "Marco",  "Ivan",
                                    "Pedro", "Luca",  "Carlos", "Sergio"};
static const char* kLastNames[] = {"Silva",  "Santos", "Fernandez", "Rossi",
                                   "Müller", "Dupont", "Ahmed",     "Kim"};
static const char* kPositions[] = {"GK", "CB", "LB", "RB", "CM", "CAM", "LW", "RW", "ST"};

ScoutGrade DraftSystem::GradeFromRating(int rating) {
  if (rating >= 80)
    return ScoutGrade::A;
  if (rating >= 70)
    return ScoutGrade::B;
  if (rating >= 60)
    return ScoutGrade::C;
  if (rating >= 50)
    return ScoutGrade::D;
  return ScoutGrade::F;
}

void DraftSystem::GenerateProspects(int /*year*/, int count) {
  m_prospects.clear();
  for (int i = 0; i < count; ++i) {
    DraftProspect p;
    p.prospectID = m_nextProspectID++;
    p.firstName = kFirstNames[blunted::GameRandInt(8)]; // NOSONAR(S2245): azar de juego, no criptográfico
    p.lastName = kLastNames[blunted::GameRandInt(8)]; // NOSONAR(S2245): azar de juego, no criptográfico
    p.age = 17 + (blunted::GameRandInt(3)); // NOSONAR(S2245): azar de juego, no criptográfico
    p.position = kPositions[blunted::GameRandInt(9)]; // NOSONAR(S2245): azar de juego, no criptográfico
    p.actualRating = 45 + (blunted::GameRandInt(40));
    p.scoutGrade = GradeFromRating(p.actualRating);
    p.projectedPick = i + 1;
    m_prospects.push_back(p);
  }
  // Sort descending by projected rating
  std::sort(m_prospects.begin(), m_prospects.end(),
            [](const DraftProspect& a, const DraftProspect& b) {
              return a.actualRating > b.actualRating;
            });
  // Update projectedPick to match the sorted order (1-based)
  for (int i = 0; i < static_cast<int>(m_prospects.size()); ++i) {
    m_prospects[i].projectedPick = i + 1;
  }
}

std::vector<std::pair<int, int>> DraftSystem::ConductDraft(const std::vector<int>& teamOrder) {
  std::vector<std::pair<int, int>> results;
  size_t pickIdx = 0;
  for (int teamID : teamOrder) {
    if (pickIdx >= m_prospects.size())
      break;
    results.emplace_back(teamID, m_prospects[pickIdx].prospectID);
    pickIdx++;
  }
  return results;
}

bool DraftSystem::TradePick(int fromTeamID, int toTeamID, int round, int pickNumber) {
  for (auto& p : m_picks) {
    if (p.owningTeamID == fromTeamID && p.round == round && p.pickNumber == pickNumber) {
      p.owningTeamID = toTeamID;
      p.isTraded = true;
      return true;
    }
  }
  return false;
}
