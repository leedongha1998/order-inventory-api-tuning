package com.example.order_api_tuning.member.persistence;

import com.example.order_api_tuning.member.domain.entity.Member;
import com.example.order_api_tuning.member.domain.repository.MemberRepository;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class MemberRepositoryImpl implements MemberRepository {

  private final JpaMemberRepository jpaMemberRepository;

  @Override
  public Optional<Member> findById(Long memberId) {
    return jpaMemberRepository.findById(memberId);
  }
}
